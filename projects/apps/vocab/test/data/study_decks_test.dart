import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vocab/data/cell.dart';
import 'package:vocab/data/study_decks.dart';
import 'package:vocab/data/study_records.dart';
import 'package:vocab/data/word.dart';

/// 이름 있는 단어장(5판 `study_decks`)과 옛 칸 기록 옮기기를 실제 sqflite(PC의 ffi)로 본다.
void main() {
  late Directory dir;
  late String path;
  late SqfliteStudyRecords records;
  late SqfliteStudyDecks decks;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('vocab_decks_test');
    path = p.join(dir.path, 'vocab.db');
    records = SqfliteStudyRecords(factory: databaseFactoryFfi, path: path);
    decks = SqfliteStudyDecks(records);
  });

  tearDown(() async {
    // 임시 폴더를 지울 수 있게 DB를 닫는다(같은 파일은 연결 하나를 함께 쓴다)
    await (await databaseFactoryFfi.openDatabase(path)).close();
    await dir.delete(recursive: true);
  });

  Word w(String id) =>
      Word(id: id, word: id, meaning: id, example: 'x', exampleMeaning: 'y');

  test('단어장은 만든 순서로 읽히고, 같은 학교급+난이도도 따로 만들어지며 이름을 바꿀 수 있다', () async {
    final a = await decks.createDeck('아침', Cell.middleMedium);
    final b = await decks.createDeck('저녁', Cell.middleMedium);
    expect(a.id, isNot(b.id));
    expect(a.id, startsWith('deck_'));
    expect(Cell.byId(a.id), isNull);

    await decks.renameDeck(a.deckId, '아침 공부');
    final list = await decks.decks();
    expect(list.map((d) => (d.deckId, d.name, d.base)), [
      (a.deckId, '아침 공부', Cell.middleMedium),
      (b.deckId, '저녁', Cell.middleMedium),
    ]);
  });

  test('단어장을 지우면 그 오답 노트와 학습·시험 기록도 지우고, 다른 단어장·칸 id 줄은 남긴다', () async {
    final a = await decks.createDeck('지울 것', Cell.elementaryEasy);
    final b = await decks.createDeck('남길 것', Cell.elementaryEasy);
    await records.recordQuizAnswer(deck: a, word: w('ee-001'), correct: false);
    await records.recordCardViewed(deck: a, word: w('ee-002'));
    await records.recordQuizAnswer(deck: b, word: w('ee-001'), correct: false);
    await records.recordCardViewed(deck: b, word: w('ee-002'));
    // 이미 지운 단어장이 남긴 줄이나 등록하지 않은 칸의 옛 기록은 건드리지 않는다
    await records.recordQuizAnswer(
      deck: Cell.elementaryEasy,
      word: w('ee-003'),
      correct: true,
    );
    await records.recordCardViewed(
      deck: Cell.elementaryEasy,
      word: w('ee-003'),
    );

    await decks.deleteDeck(a.deckId);

    expect((await decks.decks()).map((d) => d.deckId), [b.deckId]);
    expect(await records.deckWrongNotes(a), isEmpty);
    expect((await records.deckWrongNotes(b)).map((n) => n.wordId), ['ee-001']);
    final db = await records.database;
    Future<int> count(String table, String cellId) async =>
        (await db.rawQuery(
              'SELECT COUNT(*) AS n FROM $table WHERE cell_id = ?',
              [cellId],
            )).single['n']
            as int;
    expect(await count('quiz_log', a.id), 0, reason: '지운 단어장의 시험 기록도 지운다');
    expect(await count('study_log', a.id), 0, reason: '지운 단어장의 학습 기록도 지운다');
    expect(await count('quiz_log', b.id), 1);
    expect(await count('study_log', b.id), 1);
    expect(await count('quiz_log', Cell.elementaryEasy.id), 1);
    expect(await count('study_log', Cell.elementaryEasy.id), 1);
  });

  test('옛 칸 기록은 등록한 칸마다 만든 단어장으로 옮겨지고, 다시 불러도 한 번만 옮긴다', () async {
    // 옛 버전: 칸 id로 쌓인 기록(중등 중간·초등 쉬움)과 등록하지 않은 칸(고등 어려움)의 기록
    await records.recordQuizAnswer(
      deck: Cell.middleMedium,
      word: w('mm-001'),
      correct: true,
    );
    await records.recordQuizAnswer(
      deck: Cell.middleMedium,
      word: w('mm-002'),
      correct: false,
    );
    await records.recordQuizAnswer(
      deck: Cell.elementaryEasy,
      word: w('ee-001'),
      correct: false,
    );
    await records.recordQuizAnswer(
      deck: Cell.highHard,
      word: w('hh-001'),
      correct: false,
    );

    final selected = await decks.migrateLegacy(
      cells: [Cell.elementaryEasy, Cell.middleMedium, Cell.middleMedium],
      selected: Cell.middleMedium,
    );

    final list = await decks.decks();
    expect(list.map((d) => (d.name, d.base)), [
      ('초등 쉬움', Cell.elementaryEasy),
      ('중등 중간', Cell.middleMedium),
    ]);
    final [easy, middle] = list;
    expect(selected, middle.deckId);

    // 기록이 새 단어장 id로 옮겨졌다
    final pm = await records.progress(middle);
    expect((pm.memorized, pm.wrong), (1, 1));
    expect(pm.days.map((d) => d.cards + d.answered), [2]);
    expect(
      (await records.deckWrongNotes(easy)).map((n) => (n.wordId, n.missCount)),
      [('ee-001', 1)],
    );
    final oldMiddle = await records.progress(Cell.middleMedium);
    expect((oldMiddle.memorized, oldMiddle.wrong), (0, 0));
    expect(oldMiddle.days, isEmpty);
    // 등록하지 않은 칸의 기록은 지우지 않고 칸 id 그대로 둔다
    expect((await records.progress(Cell.highHard)).wrong, 1);

    // 다시 불러도(다음 실행) 새로 만들거나 옮기지 않고, 그때 고른 단어장 번호를 다시 돌려준다
    await records.recordQuizAnswer(
      deck: Cell.middleMedium,
      word: w('mm-003'),
      correct: false,
    );
    final again = await decks.migrateLegacy(
      cells: [Cell.elementaryEasy, Cell.middleMedium],
      selected: Cell.middleMedium,
    );
    expect(again, middle.deckId);
    expect(await decks.decks(), hasLength(2));
    expect((await records.progress(middle)).wrong, 1);
  });

  test('옛 기록이 없는 새 설치는 단어장을 만들지 않고, 그 뒤에 지워도 옛 칸으로 다시 만들지 않는다', () async {
    expect(await decks.migrateLegacy(cells: const []), isNull);
    expect(await decks.decks(), isEmpty);

    final deck = await decks.createDeck('첫 단어장', Cell.highEasy);
    await decks.deleteDeck(deck.deckId);
    expect(
      await decks.migrateLegacy(
        cells: [Cell.middleMedium],
        selected: Cell.middleMedium,
      ),
      isNull,
    );
    expect(await decks.decks(), isEmpty);
  });

  test('옮기는 중에 실패하면 아무것도 바뀌지 않아 다음 실행에서 처음부터 다시 옮긴다', () async {
    await records.recordQuizAnswer(
      deck: Cell.middleMedium,
      word: w('mm-001'),
      correct: false,
    );
    final db = await records.database;
    // 단어장을 만들고 study_log를 옮긴 뒤 wrong_notes를 옮기다 실패하도록 표 이름을 잠시 바꿔 둔다
    await db.execute('ALTER TABLE wrong_notes RENAME TO wrong_notes_off');
    await expectLater(
      decks.migrateLegacy(
        cells: [Cell.middleMedium],
        selected: Cell.middleMedium,
      ),
      throwsA(isA<DatabaseException>()),
    );
    await db.execute('ALTER TABLE wrong_notes_off RENAME TO wrong_notes');
    expect(await decks.decks(), isEmpty);
    final old = await records.progress(Cell.middleMedium);
    expect(
      (old.wrong, old.days.single.cards + old.days.single.answered),
      (1, 1),
    );

    final selected = await decks.migrateLegacy(
      cells: [Cell.middleMedium],
      selected: Cell.middleMedium,
    );
    final [deck] = await decks.decks();
    expect(selected, deck.deckId);
    expect((await records.progress(deck)).wrong, 1);
  });

  group('단어장마다의 설정(7판 card_count·quiz_count)', () {
    Future<List<Map<String, Object?>>> rows() async =>
        (await records.database).rawQuery(
          'SELECT id, card_count, quiz_count FROM study_decks ORDER BY id',
        );

    test('새로 만든 단어장은 카드 50·시험 20을 열에 명시적으로 저장한다', () async {
      final a = await decks.createDeck('아침', Cell.middleMedium);
      expect(await rows(), [
        {'id': a.deckId, 'card_count': 50, 'quiz_count': 20},
      ]);
      expect(await decks.loadCounts(a.deckId), (cardCount: 50, quizCount: 20));
    });

    test('한 단어장의 값을 바꾸면 그 줄만 바뀐다', () async {
      final a = await decks.createDeck('아침', Cell.middleMedium);
      final b = await decks.createDeck('저녁', Cell.middleMedium);
      await decks.saveCardCount(a.deckId, 10);
      await decks.saveQuizCount(a.deckId, 30);
      expect(await rows(), [
        {'id': a.deckId, 'card_count': 10, 'quiz_count': 30},
        {'id': b.deckId, 'card_count': 50, 'quiz_count': 20},
      ]);
      expect(await decks.loadCounts(a.deckId), (cardCount: 10, quizCount: 30));
      expect(await decks.loadCounts(b.deckId), (cardCount: 50, quizCount: 20));
    });

    test('단어장을 지우면 그 설정도 함께 없어진다', () async {
      final a = await decks.createDeck('아침', Cell.middleMedium);
      final b = await decks.createDeck('저녁', Cell.middleMedium);
      await decks.saveCardCount(a.deckId, 7);
      await decks.deleteDeck(a.deckId);
      expect(await rows(), [
        {'id': b.deckId, 'card_count': 50, 'quiz_count': 20},
      ]);
      expect(await decks.loadCounts(a.deckId), (
        cardCount: null,
        quizCount: null,
      ));
    });

    test('옛 칸 기록을 옮겨 만든 단어장은 설정 열이 비어 옛 공통 설정을 물려받는다', () async {
      await decks.migrateLegacy(cells: [Cell.middleMedium]);
      final [deck] = await decks.decks();
      expect(await decks.loadCounts(deck.deckId), (
        cardCount: null,
        quizCount: null,
      ));
    });
  });

  group('오늘의 단어(11판 daily_count·daily_words)', () {
    test('새 단어장은 오늘의 단어 개수 10을 명시적으로 저장하고, 바꾸면 그 단어장만 바뀐다', () async {
      final a = await decks.createDeck('아침', Cell.middleMedium);
      final b = await decks.createDeck('저녁', Cell.middleMedium);
      expect(await decks.loadDailyCount(a.deckId), 10);
      await decks.saveDailyCount(a.deckId, 15);
      expect(await decks.loadDailyCount(a.deckId), 15);
      expect(await decks.loadDailyCount(b.deckId), 10);
    });

    test('그날 고른 단어는 순서 그대로 남고, 다시 만들려 해도 처음 것이 그대로이며 DB를 다시 열어도 같다', () async {
      final a = await decks.createDeck('아침', Cell.middleMedium);
      expect(await decks.loadDailySet(a.deckId, '2026-11-28'), isNull);
      final first = await decks.createDailySet(a.deckId, '2026-11-28', [
        'w-3',
        'w-1',
        'w-2',
      ]);
      expect(first.wordIds, ['w-3', 'w-1', 'w-2']);
      // 같은 날 다른 곳에서 또 골라도 처음 것으로 고정된다
      final again = await decks.createDailySet(a.deckId, '2026-11-28', [
        'w-9',
      ]);
      expect(again.wordIds, ['w-3', 'w-1', 'w-2']);

      // 앱을 다시 시작한 것처럼 새 연결로 읽는다
      await (await records.database).close();
      final reopened = SqfliteStudyDecks(
        SqfliteStudyRecords(factory: databaseFactoryFfi, path: path),
      );
      final loaded = await reopened.loadDailySet(a.deckId, '2026-11-28');
      expect(loaded!.wordIds, ['w-3', 'w-1', 'w-2']);
      expect(await reopened.loadDailySet(a.deckId, '2026-11-29'), isNull);
      await (await SqfliteStudyRecords(
        factory: databaseFactoryFfi,
        path: path,
      ).database).close();
    });

    test('고른 단어를 모두 보면 완료되고 그 날이 끝낸 날에 들어간다(고르지 않은 단어는 세지 않는다)', () async {
      final a = await decks.createDeck('아침', Cell.middleMedium);
      await decks.createDailySet(a.deckId, '2026-11-28', ['w-1', 'w-2']);
      var set = await decks.markDailySeen(a.deckId, '2026-11-28', 'w-2');
      expect((set!.seenCount, set.completed), (1, false));
      set = await decks.markDailySeen(a.deckId, '2026-11-28', 'w-9');
      expect(set!.seenCount, 1);
      expect(await decks.completedDailyDays(a.deckId), isEmpty);
      set = await decks.markDailySeen(a.deckId, '2026-11-28', 'w-1');
      expect(set!.completed, isTrue);
      expect(await decks.completedDailyDays(a.deckId), {'2026-11-28'});
      // 없는 날은 null
      expect(await decks.markDailySeen(a.deckId, '2026-11-27', 'w-1'), isNull);
    });

    test('단어장을 지우면 그 단어장의 오늘의 단어도 지운다', () async {
      final a = await decks.createDeck('아침', Cell.middleMedium);
      final b = await decks.createDeck('저녁', Cell.middleMedium);
      await decks.createDailySet(a.deckId, '2026-11-28', ['w-1']);
      await decks.createDailySet(b.deckId, '2026-11-28', ['w-2']);
      await decks.deleteDeck(a.deckId);
      expect(await decks.loadDailySet(a.deckId, '2026-11-28'), isNull);
      expect(
        (await decks.loadDailySet(b.deckId, '2026-11-28'))!.wordIds,
        ['w-2'],
      );
    });
  });

  test('옛 칸 이름은 학교급 + 난이도', () {
    expect(legacyDeckName(Cell.middleMedium), '중등 중간');
    expect(legacyDeckName(Cell.elementaryHard), '초등 어려움');
  });
}
