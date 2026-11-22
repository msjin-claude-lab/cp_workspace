import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vocab/data/cell.dart';
import 'package:vocab/data/study_records.dart';
import 'package:vocab/data/word.dart';

/// 실제 sqflite 구현을 PC에서 sqflite_common_ffi로 돌린다. DB는 임시 폴더의 파일.
void main() {
  const word = Word(
    id: 'ee-001',
    word: 'apple',
    meaning: '사과',
    example: 'I eat an apple.',
    exampleMeaning: '나는 사과를 먹는다.',
  );

  late Directory dir;
  late String path;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('vocab_db_test');
    path = p.join(dir.path, 'vocab.db');
  });

  tearDown(() => dir.delete(recursive: true));

  Future<List<String>> tables(Database db) async => [
    for (final row in await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' "
      "AND name NOT LIKE 'sqlite_%' ORDER BY name",
    ))
      row['name'] as String,
  ];

  test('새로 설치하면 2판 표가 모두 생기고, 시험 결과가 기록되며 틀리면 오답 노트에 들어간다', () async {
    final records = SqfliteStudyRecords(
      factory: databaseFactoryFfi,
      path: path,
    );
    await records.recordQuizAnswer(
      deck: Cell.elementaryEasy,
      word: word,
      correct: true,
    );
    await records.recordQuizAnswer(
      deck: Cell.elementaryEasy,
      word: word,
      correct: false,
    );
    await records.recordAnswer(
      deck: Cell.elementaryEasy,
      word: word,
      known: false,
    );

    final db = await databaseFactoryFfi.openDatabase(path);
    expect(await db.getVersion(), SqfliteStudyRecords.schemaVersion);
    expect(
      await tables(db),
      containsAll(['quiz_log', 'study_log', 'wrong_notes']),
    );
    expect(
      await db.rawQuery(
        'SELECT word_id, cell_id, correct FROM quiz_log '
        'ORDER BY id',
      ),
      [
        {'word_id': 'ee-001', 'cell_id': 'elementary_easy', 'correct': 1},
        {'word_id': 'ee-001', 'cell_id': 'elementary_easy', 'correct': 0},
      ],
    );
    expect(await db.rawQuery('SELECT known FROM study_log'), [
      {'known': 0},
    ]);
    // 시험 오답 1번 + 학습 모른다 1번 → 같은 줄의 틀린 횟수 2
    expect(await db.rawQuery('SELECT word_id, miss_count FROM wrong_notes'), [
      {'word_id': 'ee-001', 'miss_count': 2},
    ]);
    await db.close();
  });

  test('오답 노트는 학교급별로 최근에 틀린 것부터 읽히고, 빼면 노트만 지워지고 기록은 남는다', () async {
    final records = SqfliteStudyRecords(
      factory: databaseFactoryFfi,
      path: path,
    );
    const middle = Word(
      id: 'mh-001',
      word: 'improve',
      meaning: '나아지다',
      example: 'x',
      exampleMeaning: 'y',
    );
    await records.recordAnswer(
      deck: Cell.elementaryEasy,
      word: word,
      known: false,
    );
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await records.recordQuizAnswer(
      deck: Cell.middleHard,
      word: middle,
      correct: false,
    );

    final elementary = await records.wrongNotes(SchoolLevel.elementary);
    expect(elementary.map((n) => (n.wordId, n.deck, n.missCount)), [
      ('ee-001', Cell.elementaryEasy, 1),
    ]);
    expect(
      (await records.wrongNotes(SchoolLevel.middle)).map((n) => n.wordId),
      ['mh-001'],
    );
    expect(await records.wrongNotes(SchoolLevel.high), isEmpty);

    // 같은 학교급에 나중에 틀린 단어는 위로 온다(SQL의 최근순 정렬)
    await Future<void>.delayed(const Duration(milliseconds: 5));
    const later = Word(
      id: 'eh-001',
      word: 'castle',
      meaning: '성',
      example: 'x',
      exampleMeaning: 'y',
    );
    await records.recordQuizAnswer(
      deck: Cell.elementaryHard,
      word: later,
      correct: false,
    );
    expect(
      (await records.wrongNotes(SchoolLevel.elementary)).map((n) => n.wordId),
      ['eh-001', 'ee-001'],
    );
    await records.removeWrongNote('eh-001');

    await records.removeWrongNote('ee-001');
    expect(await records.wrongNotes(SchoolLevel.elementary), isEmpty);

    final db = await databaseFactoryFfi.openDatabase(path);
    expect(await db.rawQuery('SELECT word_id FROM study_log'), [
      {'word_id': 'ee-001'},
    ], reason: '오답 노트에서 빼도 학습 기록은 남는다');
    await db.close();
  });

  test('1판 사용자의 DB는 기록을 그대로 둔 채 2판으로 올라가 시험 기록을 쓸 수 있다', () async {
    // 1판(카드 학습만 있던 때)으로 만든 DB에 기록 하나
    final v1 = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => SqfliteStudyRecords.createV1(db),
      ),
    );
    await v1.insert('study_log', {
      'word_id': 'ee-002',
      'cell_id': 'elementary_easy',
      'known': 1,
      'answered_at': 1,
      'answered_day': '2026-11-19',
    });
    await v1.close();

    final records = SqfliteStudyRecords(
      factory: databaseFactoryFfi,
      path: path,
    );
    await records.recordQuizAnswer(
      deck: Cell.elementaryEasy,
      word: word,
      correct: false,
    );

    final db = await databaseFactoryFfi.openDatabase(path);
    expect(await db.getVersion(), SqfliteStudyRecords.schemaVersion);
    expect(await db.rawQuery('SELECT word_id FROM study_log'), [
      {'word_id': 'ee-002'},
    ]);
    expect(await db.rawQuery('SELECT word_id, correct FROM quiz_log'), [
      {'word_id': 'ee-001', 'correct': 0},
    ]);
    expect(await db.rawQuery('SELECT word_id, miss_count FROM wrong_notes'), [
      {'word_id': 'ee-001', 'miss_count': 1},
    ]);
    await db.close();
  });

  test('2판 사용자의 DB는 시험 기록을 그대로 둔 채 3판(단어별 인덱스)으로 올라간다', () async {
    // 2판: 1판 표 + quiz_log(인덱스 quiz_log_word 없음)
    final v2 = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, _) async {
          await SqfliteStudyRecords.createV1(db);
          await db.execute(
            'CREATE TABLE quiz_log(id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'word_id TEXT NOT NULL, cell_id TEXT NOT NULL, '
            'correct INTEGER NOT NULL, answered_at INTEGER NOT NULL, '
            'answered_day TEXT NOT NULL)',
          );
        },
      ),
    );
    await v2.insert('quiz_log', {
      'word_id': 'ee-001',
      'cell_id': 'elementary_easy',
      'correct': 1,
      'answered_at': 1,
      'answered_day': '2026-11-20',
    });
    await v2.close();

    final records = SqfliteStudyRecords(
      factory: databaseFactoryFfi,
      path: path,
    );
    final progress = await records.progress();
    expect(progress.memorized, {Cell.elementaryEasy: 1});

    final db = await databaseFactoryFfi.openDatabase(path);
    // 2판에서 3판(인덱스)을 거쳐 지금 판까지 차례로 올라간다
    expect(await db.getVersion(), SqfliteStudyRecords.schemaVersion);
    expect(
      await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'index' "
        "AND name = 'quiz_log_word'",
      ),
      hasLength(1),
    );
    await db.close();
  });

  test('진도: 외운 수는 단어별 마지막 시험 답으로 세고, 오답 수와 날짜별 기록을 모은다', () async {
    final records = SqfliteStudyRecords(
      factory: databaseFactoryFfi,
      path: path,
    );
    Word w(String id) =>
        Word(id: id, word: id, meaning: id, example: 'x', exampleMeaning: 'y');
    Future<void> quiz(
      String id,
      bool correct, [
      Cell cell = Cell.elementaryEasy,
    ]) => records.recordQuizAnswer(deck: cell, word: w(id), correct: correct);

    await quiz('ee-001', false); // 틀렸다가
    await quiz('ee-001', true); // 맞힘 → 외움
    await quiz('ee-002', true); // 맞혔다가
    await quiz('ee-002', false); // 틀림 → 해제
    await quiz('ee-003', true); // 외움
    await quiz('mh-001', true, Cell.middleHard);
    await records.recordAnswer(
      deck: Cell.elementaryEasy,
      word: w('ee-004'),
      known: true, // 카드 학습의 '안다'는 외운 수에 들어가지 않는다
    );

    final p = await records.progress();
    expect(p.memorized, {Cell.elementaryEasy: 2, Cell.middleHard: 1});
    // 오답 노트: ee-001(틀린 적 있음 — 일반 시험에서 맞혀도 남는다), ee-002
    expect(p.wrong, {Cell.elementaryEasy: 2});
    final today = dayKey(DateTime.now());
    expect(p.days.map((d) => (d.day, d.studied, d.correct)), [(today, 7, 4)]);
    expect(p.elapsedDays(DateTime.now()), 1);
    // 칸 하나만: 날짜별 기록은 그 칸 것만 센다(초등 쉬움 6건 · 맞힘 3, 중등 어려움 1건 · 맞힘 1)
    final easy = await records.progress(only: Cell.elementaryEasy);
    expect(easy.days.map((d) => (d.studied, d.correct)), [(6, 3)]);
    final hard = await records.progress(only: Cell.middleHard);
    expect(hard.days.map((d) => (d.studied, d.correct)), [(1, 1)]);
    expect((await records.progress(only: Cell.highEasy)).days, isEmpty);
    // 임시 폴더를 지울 수 있게 DB를 닫는다(같은 파일은 연결 하나를 함께 쓴다)
    await (await databaseFactoryFfi.openDatabase(path)).close();
  });

  test('진행 일수는 처음 공부한 날을 1일로 치고 오늘까지 달력 날짜로 센다', () {
    Progress days(List<String> list) => Progress(
      days: [for (final d in list) DayStat(day: d, studied: 1, correct: 0)],
    );
    final today = DateTime(2026, 11, 22, 23, 59);

    expect(days([]).elapsedDays(today), 0);
    expect(days(['2026-11-22']).elapsedDays(today), 1);
    // 20일에만 공부하고 쉬었어도 22일에는 3일째
    expect(days(['2026-11-20']).elapsedDays(today), 3);
    // 가장 이른 날부터 센다(목록 순서와 상관없이)
    expect(
      days(['2026-11-21', '2026-11-18', '2026-11-20']).elapsedDays(today),
      5,
    );
    // 달·해가 바뀌어도 센다
    expect(days(['2026-10-31']).elapsedDays(DateTime(2026, 11, 1)), 2);
    expect(days(['2025-12-31']).elapsedDays(DateTime(2026, 1, 1)), 2);
    // 기기 날짜가 첫 기록보다 앞이어도 0 이하가 되지 않는다
    expect(days(['2026-11-25']).elapsedDays(today), 1);
  });
}
