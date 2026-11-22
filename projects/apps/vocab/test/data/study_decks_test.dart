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

  test('단어장을 지우면 그 오답 노트만 지우고, 학습·시험 기록과 다른 단어장은 남긴다', () async {
    final a = await decks.createDeck('지울 것', Cell.elementaryEasy);
    final b = await decks.createDeck('남길 것', Cell.elementaryEasy);
    await records.recordQuizAnswer(deck: a, word: w('ee-001'), correct: false);
    await records.recordCardViewed(deck: a, word: w('ee-002'));
    await records.recordQuizAnswer(deck: b, word: w('ee-001'), correct: false);

    await decks.deleteDeck(a.deckId);

    expect((await decks.decks()).map((d) => d.deckId), [b.deckId]);
    expect(await records.deckWrongNotes(a), isEmpty);
    expect((await records.deckWrongNotes(b)).map((n) => n.wordId), ['ee-001']);
    final db = await records.database;
    expect(
      await db.rawQuery(
        'SELECT COUNT(*) AS n FROM quiz_log WHERE cell_id = ?',
        [a.id],
      ),
      [
        {'n': 1},
      ],
      reason: '단어장을 지워도 시험 기록은 남는다',
    );
    expect(
      await db.rawQuery(
        'SELECT COUNT(*) AS n FROM study_log WHERE cell_id = ?',
        [a.id],
      ),
      [
        {'n': 1},
      ],
      reason: '단어장을 지워도 학습 기록은 남는다',
    );
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

  test('옛 칸 이름은 학교급 + 난이도', () {
    expect(legacyDeckName(Cell.middleMedium), '중등 중간');
    expect(legacyDeckName(Cell.elementaryHard), '초등 어려움');
  });
}
