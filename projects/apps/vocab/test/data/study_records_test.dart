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
      cell: Cell.elementaryEasy,
      word: word,
      correct: true,
    );
    await records.recordQuizAnswer(
      cell: Cell.elementaryEasy,
      word: word,
      correct: false,
    );
    await records.recordAnswer(
      cell: Cell.elementaryEasy,
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
      cell: Cell.elementaryEasy,
      word: word,
      known: false,
    );
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await records.recordQuizAnswer(
      cell: Cell.middleHard,
      word: middle,
      correct: false,
    );

    final elementary = await records.wrongNotes(SchoolLevel.elementary);
    expect(elementary.map((n) => (n.wordId, n.cell, n.missCount)), [
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
      cell: Cell.elementaryHard,
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
      cell: Cell.elementaryEasy,
      word: word,
      correct: false,
    );

    final db = await databaseFactoryFfi.openDatabase(path);
    expect(await db.getVersion(), 2);
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
}
