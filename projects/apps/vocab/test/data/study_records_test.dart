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

  test('새로 설치하면 지금 판의 표가 모두 생기고, 시험 결과가 기록되며 틀리면 오답 노트에 들어간다', () async {
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
    await records.recordCardViewed(deck: Cell.elementaryEasy, word: word);
    await records.recordCardViewed(deck: Cell.elementaryEasy, word: word);

    // 넘겨 본 단어는 단어장별로, 여러 번 봐도 한 번만 나온다(시험만 본 단어는 아니다)
    expect(await records.viewedWordIds(Cell.elementaryEasy), {'ee-001'});
    expect(await records.viewedWordIds(Cell.elementaryMedium), isEmpty);

    final db = await databaseFactoryFfi.openDatabase(path);
    expect(await db.getVersion(), SqfliteStudyRecords.schemaVersion);
    expect(
      await tables(db),
      containsAll(['quiz_log', 'study_log', 'wrong_notes']),
    );
    // 직접 단어를 넣는 내 단어장 표는 6판부터 만들지 않는다
    expect(await tables(db), isNot(contains('word_books')));
    expect(await tables(db), isNot(contains('book_words')));
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
      {'known': 1},
      {'known': 1},
    ]);
    // 카드를 넘겨 본 것은 오답 노트에 넣지 않는다(시험 오답 1번만 센다)
    expect(await db.rawQuery('SELECT word_id, miss_count FROM wrong_notes'), [
      {'word_id': 'ee-001', 'miss_count': 1},
    ]);
    await db.close();
  });

  test('오답 노트는 단어 묶음마다 최근에 틀린 것부터 읽히고, 빼면 노트만 지워지고 기록은 남는다', () async {
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
    await records.recordQuizAnswer(
      deck: Cell.elementaryEasy,
      word: word,
      correct: false,
    );
    await records.recordCardViewed(deck: Cell.elementaryEasy, word: word);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await records.recordQuizAnswer(
      deck: Cell.middleHard,
      word: middle,
      correct: false,
    );

    final elementary = await records.deckWrongNotes(Cell.elementaryEasy);
    expect(elementary.map((n) => (n.wordId, n.deck, n.missCount)), [
      ('ee-001', Cell.elementaryEasy, 1),
    ]);
    expect(
      (await records.deckWrongNotes(Cell.middleHard)).map((n) => n.wordId),
      ['mh-001'],
    );
    expect(await records.deckWrongNotes(Cell.highEasy), isEmpty);

    // 같은 묶음에 나중에 틀린 단어는 위로 온다(SQL의 최근순 정렬)
    await Future<void>.delayed(const Duration(milliseconds: 5));
    const later = Word(
      id: 'ee-002',
      word: 'castle',
      meaning: '성',
      example: 'x',
      exampleMeaning: 'y',
    );
    await records.recordQuizAnswer(
      deck: Cell.elementaryEasy,
      word: later,
      correct: false,
    );
    expect(
      (await records.deckWrongNotes(Cell.elementaryEasy)).map((n) => n.wordId),
      ['ee-002', 'ee-001'],
    );
    await records.removeWrongNote(Cell.elementaryEasy, 'ee-002');

    await records.removeWrongNote(Cell.elementaryEasy, 'ee-001');
    expect(await records.deckWrongNotes(Cell.elementaryEasy), isEmpty);

    final db = await databaseFactoryFfi.openDatabase(path);
    expect(await db.rawQuery('SELECT word_id FROM study_log'), [
      {'word_id': 'ee-001'},
    ], reason: '오답 노트에서 빼도 학습 기록은 남는다');
    await db.close();
  });

  test('1판 사용자의 DB는 기록을 그대로 둔 채 지금 판으로 올라가 시험 기록을 쓸 수 있다', () async {
    // 1판(카드 학습만 있던 때)으로 만든 DB에 기록 하나
    final v1 = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => SqfliteStudyRecords.createV1(db),
      ),
    );
    // 옛 초등 번호(ee- 등)의 기록은 8판에서 지우므로 중등 번호로 본다
    await v1.insert('study_log', {
      'word_id': 'mm-002',
      'cell_id': 'middle_medium',
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
      {'word_id': 'mm-002'},
    ]);
    expect(await db.rawQuery('SELECT word_id, correct FROM quiz_log'), [
      {'word_id': 'ee-001', 'correct': 0},
    ]);
    expect(await db.rawQuery('SELECT word_id, miss_count FROM wrong_notes'), [
      {'word_id': 'ee-001', 'miss_count': 1},
    ]);
    await db.close();
  });

  test('2판 사용자의 DB는 시험 기록을 그대로 둔 채 지금 판까지 올라가 단어장별 인덱스가 생긴다', () async {
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
      'word_id': 'mm-001',
      'cell_id': 'middle_medium',
      'correct': 1,
      'answered_at': 1,
      'answered_day': '2026-11-20',
    });
    await v2.close();

    final records = SqfliteStudyRecords(
      factory: databaseFactoryFfi,
      path: path,
    );
    final progress = await records.progress(Cell.middleMedium);
    expect(progress.memorized, 1);

    final db = await databaseFactoryFfi.openDatabase(path);
    // 2판에서 3판(인덱스)을 거쳐 지금 판까지 차례로 올라간다. 단어별 인덱스는 5판에서
    // 단어장별(cell_id, word_id, id)로 바뀐다
    expect(await db.getVersion(), SqfliteStudyRecords.schemaVersion);
    expect(
      await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'index' "
        "AND name = 'quiz_log_deck_word'",
      ),
      hasLength(1),
    );
    await db.close();
  });

  test('새 설치와 1판·3판·6판 DB를 지금 판으로 올린 DB는 sqlite_master가 같다', () async {
    Future<List<Map<String, Object?>>> master(String file) async {
      final db = await databaseFactoryFfi.openDatabase(p.join(dir.path, file));
      final rows = await db.rawQuery(
        'SELECT type, name, tbl_name, sql FROM sqlite_master '
        "WHERE name NOT LIKE 'sqlite_%' AND name <> 'android_metadata' "
        'ORDER BY name',
      );
      await db.close();
      return rows;
    }

    // 새 설치
    await (await SqfliteStudyRecords(
      factory: databaseFactoryFfi,
      path: p.join(dir.path, 'fresh.db'),
    ).database).close();

    // 1판·3판·6판 사용자의 DB(기록은 비어 있어도 판 번호가 옛것이면 올라온다)
    for (final (file, version, create) in [
      ('v1.db', 1, SqfliteStudyRecords.createV1),
      ('v3.db', 3, SqfliteStudyRecords.createV3),
      ('v6.db', 6, SqfliteStudyRecords.createV6),
    ]) {
      final old = await databaseFactoryFfi.openDatabase(
        p.join(dir.path, file),
        options: OpenDatabaseOptions(
          version: version,
          onCreate: (db, _) => create(db),
        ),
      );
      await old.close();
      await (await SqfliteStudyRecords(
        factory: databaseFactoryFfi,
        path: p.join(dir.path, file),
      ).database).close();
    }

    final fresh = await master('fresh.db');
    expect(fresh, isNotEmpty);
    expect(await master('v1.db'), fresh);
    expect(await master('v3.db'), fresh);
    expect(await master('v6.db'), fresh);
  });

  test('6판 사용자의 DB는 7판으로 올라가며 단어장마다 설정 열이 NULL로 생기고, 기존 줄·기록은 그대로다', () async {
    final v6 = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 6,
        onCreate: (db, _) => SqfliteStudyRecords.createV6(db),
      ),
    );
    await v6.insert('study_decks', {
      'name': '아침',
      'cell_id': 'middle_medium',
      'created_at': 1,
    });
    await v6.insert('study_decks', {
      'name': '저녁',
      'cell_id': 'elementary_easy',
      'created_at': 2,
    });
    await v6.insert('quiz_log', {
      'word_id': 'mm-001',
      'cell_id': 'deck_1',
      'correct': 0,
      'answered_at': 3,
      'answered_day': '2026-11-22',
    });
    await v6.insert('study_log', {
      'word_id': 'w-0001',
      'cell_id': 'deck_2',
      'known': 1,
      'answered_at': 4,
      'answered_day': '2026-11-22',
    });
    await v6.insert('wrong_notes', {
      'word_id': 'mm-001',
      'cell_id': 'deck_1',
      'miss_count': 1,
      'first_missed_at': 3,
      'last_missed_at': 3,
    });
    await v6.insert('app_meta', {'key': 'legacy_cells_migrated', 'value': ''});
    await v6.close();

    final db = await SqfliteStudyRecords(
      factory: databaseFactoryFfi,
      path: path,
    ).database;
    expect(await db.getVersion(), SqfliteStudyRecords.schemaVersion);
    expect(
      await db.rawQuery(
        'SELECT id, name, cell_id, created_at, card_count, quiz_count '
        'FROM study_decks ORDER BY id',
      ),
      [
        {
          'id': 1,
          'name': '아침',
          'cell_id': 'middle_medium',
          'created_at': 1,
          'card_count': null,
          'quiz_count': null,
        },
        {
          'id': 2,
          'name': '저녁',
          'cell_id': 'elementary_easy',
          'created_at': 2,
          'card_count': null,
          'quiz_count': null,
        },
      ],
    );
    expect(
      await db.rawQuery(
        'SELECT word_id, cell_id, correct, answered_at, answered_day '
        'FROM quiz_log',
      ),
      [
        {
          'word_id': 'mm-001',
          'cell_id': 'deck_1',
          'correct': 0,
          'answered_at': 3,
          'answered_day': '2026-11-22',
        },
      ],
    );
    expect(
      await db.rawQuery(
        'SELECT word_id, cell_id, known, answered_at FROM study_log',
      ),
      [
        {
          'word_id': 'w-0001',
          'cell_id': 'deck_2',
          'known': 1,
          'answered_at': 4,
        },
      ],
    );
    expect(
      await db.rawQuery(
        'SELECT word_id, cell_id, miss_count, first_missed_at, last_missed_at '
        'FROM wrong_notes',
      ),
      [
        {
          'word_id': 'mm-001',
          'cell_id': 'deck_1',
          'miss_count': 1,
          'first_missed_at': 3,
          'last_missed_at': 3,
        },
      ],
    );
    expect(await db.rawQuery('SELECT key, value FROM app_meta'), [
      {'key': 'legacy_cells_migrated', 'value': ''},
    ]);
    await db.close();
  });

  test('7판 사용자의 DB는 8판으로 올라가며 옛 초등 번호(ee-·em-·eh-)의 기록과 오답 노트만 지운다', () async {
    final v7 = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 7,
        onCreate: (db, _) => SqfliteStudyRecords.createV7(db),
      ),
    );
    await v7.insert('study_decks', {
      'name': '아침',
      'cell_id': 'elementary_easy',
      'created_at': 1,
      'card_count': 20,
      'quiz_count': 50,
    });
    // (단어 번호, 단어장·칸) — 옛 초등 번호는 단어장 것이든 칸 것이든 지우고, 나머지는 남긴다
    const rows = [
      ('ee-010', 'deck_1'),
      ('em-001', 'deck_4'),
      ('eh-004', 'elementary_hard'),
      ('w-0010', 'deck_1'),
      ('mm-007', 'middle_medium'),
      ('me-001', 'deck_2'),
      ('mh-033', 'deck_5'),
      ('he-001', 'high_easy'),
      ('hh-050', 'high_hard'),
    ];
    var at = 0;
    for (final (wordId, cellId) in rows) {
      at++;
      await v7.insert('study_log', {
        'word_id': wordId,
        'cell_id': cellId,
        'known': 1,
        'answered_at': at,
        'answered_day': '2026-11-22',
      });
      await v7.insert('quiz_log', {
        'word_id': wordId,
        'cell_id': cellId,
        'correct': 0,
        'answered_at': at,
        'answered_day': '2026-11-22',
      });
      await v7.insert('wrong_notes', {
        'word_id': wordId,
        'cell_id': cellId,
        'miss_count': 1,
        'first_missed_at': at,
        'last_missed_at': at,
      });
    }
    await v7.close();

    final records = SqfliteStudyRecords(
      factory: databaseFactoryFfi,
      path: path,
    );
    final db = await records.database;
    expect(await db.getVersion(), 8);
    const kept = ['he-001', 'hh-050', 'me-001', 'mh-033', 'mm-007', 'w-0010'];
    for (final table in ['study_log', 'quiz_log', 'wrong_notes']) {
      expect(
        [
          for (final row in await db.rawQuery(
            'SELECT word_id FROM $table ORDER BY word_id',
          ))
            row['word_id'],
        ],
        kept,
        reason: table,
      );
    }
    // 단어장과 그 설정은 그대로다
    expect(
      await db.rawQuery(
        'SELECT name, cell_id, card_count, quiz_count FROM study_decks',
      ),
      [
        {
          'name': '아침',
          'cell_id': 'elementary_easy',
          'card_count': 20,
          'quiz_count': 50,
        },
      ],
    );
    // 진도도 지금 번호의 기록만 센다(옛 번호 ee-010의 오답은 사라졌다)
    final progress = await records.progress(
      const StudyDeck(deckId: 1, name: '아침', base: Cell.elementaryEasy),
    );
    expect(progress.wrong, 1);
    expect(progress.memorized, 0);
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
    // 카드를 넘겨 본 것은 외운 수·오답 수에 들어가지 않고 공부 수에만 든다
    await records.recordCardViewed(
      deck: Cell.elementaryEasy,
      word: w('ee-004'),
    );

    final easy = await records.progress(Cell.elementaryEasy);
    expect(easy.memorized, 2);
    // 오답 노트: ee-001(틀린 적 있음 — 일반 시험에서 맞혀도 남는다), ee-002
    expect(easy.wrong, 2);
    final today = dayKey(DateTime.now());
    // 날짜별 기록은 그 묶음 것만 세고, 카드 수와 시험 답 수를 따로 센다
    // (초등 쉬움 카드 1장 · 시험 5문제 · 맞힘 3, 중등 어려움 시험 1문제 · 맞힘 1)
    expect(easy.days.map((d) => (d.day, d.cards, d.answered, d.correct)), [
      (today, 1, 5, 3),
    ]);
    expect(easy.elapsedDays(DateTime.now()), 1);
    final hard = await records.progress(Cell.middleHard);
    expect((hard.memorized, hard.wrong), (1, 0));
    expect(hard.days.map((d) => (d.cards, d.answered, d.correct)), [(0, 1, 1)]);
    final none = await records.progress(Cell.highEasy);
    expect((none.memorized, none.wrong), (0, 0));
    expect(none.days, isEmpty);
    // 임시 폴더를 지울 수 있게 DB를 닫는다(같은 파일은 연결 하나를 함께 쓴다)
    await (await databaseFactoryFfi.openDatabase(path)).close();
  });

  test('4판 사용자의 DB는 5판을 거쳐 6판으로 올라가고, 오답 노트 기본 키가 (cell_id, word_id)가 되며 내 단어장은 지워진다', () async {
    final v4 = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 4,
        onCreate: (db, _) => SqfliteStudyRecords.createV4(db),
      ),
    );
    await v4.insert('study_log', {
      'word_id': 'mm-001',
      'cell_id': 'middle_medium',
      'known': 0,
      'answered_at': 1,
      'answered_day': '2026-11-21',
    });
    // 맞힘 1번, 틀림 3번(6판은 틀린 횟수·마지막 시각을 노트가 생긴 뒤의 시험 오답으로 맞춘다)
    for (final correct in [1, 0, 0, 0]) {
      await v4.insert('quiz_log', {
        'word_id': 'mm-001',
        'cell_id': 'middle_medium',
        'correct': correct,
        'answered_at': 2,
        'answered_day': '2026-11-21',
      });
    }
    for (final (wordId, cellId, miss) in [
      ('mm-001', 'middle_medium', 3),
      ('bw-1', 'book_1', 1),
    ]) {
      await v4.insert('wrong_notes', {
        'word_id': wordId,
        'cell_id': cellId,
        'miss_count': miss,
        'first_missed_at': 1,
        'last_missed_at': 5,
      });
    }
    await v4.insert('word_books', {'name': '내 것', 'created_at': 1});
    await v4.close();

    final records = SqfliteStudyRecords(
      factory: databaseFactoryFfi,
      path: path,
    );
    final db = await records.database;
    expect(await db.getVersion(), SqfliteStudyRecords.schemaVersion);
    expect(
      await tables(db),
      containsAll(['study_decks', 'app_meta', 'wrong_notes']),
    );
    expect(await tables(db), isNot(contains('word_books')));
    expect(await db.rawQuery('SELECT COUNT(*) AS n FROM study_log'), [
      {'n': 1},
    ]);
    expect(await db.rawQuery('SELECT COUNT(*) AS n FROM quiz_log'), [
      {'n': 4},
    ]);
    // 내 단어장(book_1)의 오답 노트는 6판에서 지워진다
    expect(
      await db.rawQuery(
        'SELECT word_id, cell_id, miss_count, first_missed_at, last_missed_at '
        'FROM wrong_notes ORDER BY word_id',
      ),
      [
        {
          'word_id': 'mm-001',
          'cell_id': 'middle_medium',
          'miss_count': 3,
          'first_missed_at': 1,
          'last_missed_at': 2,
        },
      ],
    );
    // 기본 키: cell_id(pk 1), word_id(pk 2)
    final columns = await db.rawQuery('PRAGMA table_info(wrong_notes)');
    expect({
      for (final c in columns) c['name']: c['pk'],
    }, containsPair('cell_id', 1));
    expect({
      for (final c in columns) c['name']: c['pk'],
    }, containsPair('word_id', 2));
    // 같은 단어를 다른 단어장 id로 넣을 수 있다(4판에서는 word_id 하나가 기본 키라 막혔다)
    await db.insert('wrong_notes', {
      'word_id': 'mm-001',
      'cell_id': 'deck_1',
      'miss_count': 1,
      'first_missed_at': 9,
      'last_missed_at': 9,
    });
    expect(await db.rawQuery('SELECT COUNT(*) AS n FROM wrong_notes'), [
      {'n': 2},
    ]);
    await db.close();
  });

  test('5판 사용자의 DB는 6판으로 올라가며 시험에서 틀린 적 없는 오답 노트와 내 단어장(book_) 기록·표를 지운다', () async {
    final v5 = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 5,
        onCreate: (db, _) => SqfliteStudyRecords.createV5(db),
      ),
    );
    var at = 0;
    Future<void> quiz(String cellId, String wordId, bool correct) =>
        v5.insert('quiz_log', {
          'word_id': wordId,
          'cell_id': cellId,
          'correct': correct ? 1 : 0,
          'answered_at': ++at,
          'answered_day': '2026-11-21',
        });
    Future<void> study(String cellId, String wordId) => v5.insert('study_log', {
      'word_id': wordId,
      'cell_id': cellId,
      'known': 0,
      'answered_at': ++at,
      'answered_day': '2026-11-21',
    });
    // first·last: 노트가 생긴 시각과 마지막으로 틀린 시각. 시험 답의 시각은 넣은 순서대로 1, 2, 3 …
    Future<void> note(
      String cellId,
      String wordId,
      int miss, {
      required int first,
      required int last,
    }) => v5.insert('wrong_notes', {
      'word_id': wordId,
      'cell_id': cellId,
      'miss_count': miss,
      'first_missed_at': first,
      'last_missed_at': last,
    });

    // deck_1: mm-001은 시험에서 두 번 틀림(시각 1, 3). 옛 카드 '모른다'까지 세어 노트는 5회
    await quiz('deck_1', 'mm-001', false); // 1
    await quiz('deck_1', 'mm-001', true); // 2
    await quiz('deck_1', 'mm-001', false); // 3
    await quiz('deck_1', 'mm-002', true); // 4
    // mm-003은 deck_2 시험에서만 틀림
    await quiz('deck_2', 'mm-003', false); // 5
    // 등록하지 않았던 칸의 기록. 옛 초등 번호(ee- 등)는 8판에서 지우므로 지금 초등 번호로 본다
    await quiz('elementary_easy', 'w-0001', false); // 6
    await quiz('book_1', 'bw-1', false); // 7
    await study('deck_1', 'mm-002'); // 8
    await study('elementary_easy', 'w-0002'); // 9
    await study('book_1', 'bw-1'); // 10
    // LIKE의 `_`처럼 아무 글자로 읽으면 지워질 id — 지우면 안 된다
    await study('bookx1', 'x-1'); // 11
    // 카드 '모른다'(0)로 생기고 마지막도 카드(200) → 남고, 횟수 2·마지막 3(시험 기준)으로
    await note('deck_1', 'mm-001', 5, first: 0, last: 200);
    await note('deck_1', 'mm-002', 1, first: 0, last: 0); // 카드 '모른다'만 → 지움
    // 다른 단어장(deck_2)에서만 틀림 → 지움
    await note('deck_1', 'mm-003', 1, first: 0, last: 0);
    await note('deck_2', 'mm-003', 1, first: 5, last: 5); // 남음
    // mm-004: 시험에서 세 번 틀렸지만, 오답 시험에서 맞혀 노트에서 빠졌다가 다시 틀려(15) 새로 생긴 노트(1회).
    // 빠지기 전의 오답까지 다시 세어 횟수가 늘면 안 된다
    await quiz('deck_2', 'mm-004', false); // 12
    await quiz('deck_2', 'mm-004', false); // 13
    await quiz('deck_2', 'mm-004', true); // 14
    await quiz('deck_2', 'mm-004', false); // 15
    await note('deck_2', 'mm-004', 1, first: 15, last: 15); // 남고 1회 그대로
    // mm-005: 시험에서 틀리고(16) 오답 시험에서 맞혀 빠진 뒤, 카드 '모른다'(50)로 다시 생긴 노트.
    // 지금 노트가 생긴 뒤에는 시험에서 틀린 적이 없다 → 지움
    await quiz('deck_1', 'mm-005', false); // 16
    await note('deck_1', 'mm-005', 1, first: 50, last: 50);
    // mm-006: 시험에서 틀리고(17) 빠졌다가, 다시 시험에서 틀려(18) 생긴 노트에 카드 '모른다' 3번(마지막 300).
    // 노트가 생긴 뒤의 시험 오답은 한 번 → 1회, 마지막 18
    await quiz('deck_1', 'mm-006', false); // 17
    await quiz('deck_1', 'mm-006', false); // 18
    await note('deck_1', 'mm-006', 4, first: 18, last: 300);
    // 등록하지 않았던 칸의 오답 노트도 같이 정리한다(2026-11-22 사용자 결정) → 남고 1회·마지막 6
    await note('elementary_easy', 'w-0001', 3, first: 0, last: 200);
    // 카드 '모른다'만 → 지움
    await note('elementary_easy', 'w-0002', 1, first: 0, last: 0);
    await note('book_1', 'bw-1', 1, first: 7, last: 7); // 내 단어장 → 지움
    await v5.insert('word_books', {'name': '내 것', 'created_at': 1});
    await v5.insert('book_words', {
      'book_id': 1,
      'word': 'cat',
      'meaning': '고양이',
      'created_at': 1,
    });
    await v5.close();

    final records = SqfliteStudyRecords(
      factory: databaseFactoryFfi,
      path: path,
    );
    final db = await records.database;
    expect(await db.getVersion(), SqfliteStudyRecords.schemaVersion);
    expect(SqfliteStudyRecords.schemaVersion, 8);
    final names = await tables(db);
    expect(names, isNot(contains('word_books')));
    expect(names, isNot(contains('book_words')));
    expect(
      await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE name = 'book_words_book'",
      ),
      isEmpty,
    );
    expect(
      await db.rawQuery(
        'SELECT cell_id, word_id, miss_count, first_missed_at, last_missed_at '
        'FROM wrong_notes ORDER BY cell_id, word_id',
      ),
      [
        {
          'cell_id': 'deck_1',
          'word_id': 'mm-001',
          'miss_count': 2,
          'first_missed_at': 0,
          'last_missed_at': 3,
        },
        {
          'cell_id': 'deck_1',
          'word_id': 'mm-006',
          'miss_count': 1,
          'first_missed_at': 18,
          'last_missed_at': 18,
        },
        {
          'cell_id': 'deck_2',
          'word_id': 'mm-003',
          'miss_count': 1,
          'first_missed_at': 5,
          'last_missed_at': 5,
        },
        {
          'cell_id': 'deck_2',
          'word_id': 'mm-004',
          'miss_count': 1,
          'first_missed_at': 15,
          'last_missed_at': 15,
        },
        {
          'cell_id': 'elementary_easy',
          'word_id': 'w-0001',
          'miss_count': 1,
          'first_missed_at': 0,
          'last_missed_at': 6,
        },
      ],
    );
    expect(
      await db.rawQuery(
        'SELECT cell_id, word_id, correct FROM quiz_log ORDER BY id',
      ),
      [
        {'cell_id': 'deck_1', 'word_id': 'mm-001', 'correct': 0},
        {'cell_id': 'deck_1', 'word_id': 'mm-001', 'correct': 1},
        {'cell_id': 'deck_1', 'word_id': 'mm-001', 'correct': 0},
        {'cell_id': 'deck_1', 'word_id': 'mm-002', 'correct': 1},
        {'cell_id': 'deck_2', 'word_id': 'mm-003', 'correct': 0},
        {'cell_id': 'elementary_easy', 'word_id': 'w-0001', 'correct': 0},
        {'cell_id': 'deck_2', 'word_id': 'mm-004', 'correct': 0},
        {'cell_id': 'deck_2', 'word_id': 'mm-004', 'correct': 0},
        {'cell_id': 'deck_2', 'word_id': 'mm-004', 'correct': 1},
        {'cell_id': 'deck_2', 'word_id': 'mm-004', 'correct': 0},
        {'cell_id': 'deck_1', 'word_id': 'mm-005', 'correct': 0},
        {'cell_id': 'deck_1', 'word_id': 'mm-006', 'correct': 0},
        {'cell_id': 'deck_1', 'word_id': 'mm-006', 'correct': 0},
      ],
    );
    expect(
      await db.rawQuery('SELECT cell_id, word_id FROM study_log ORDER BY id'),
      [
        {'cell_id': 'deck_1', 'word_id': 'mm-002'},
        {'cell_id': 'elementary_easy', 'word_id': 'w-0002'},
        {'cell_id': 'bookx1', 'word_id': 'x-1'},
      ],
    );
    await db.close();
  });

  test('같은 칸으로 만든 단어장 둘은 오답 노트·외운 수·날짜별 기록이 따로 쌓인다', () async {
    final records = SqfliteStudyRecords(
      factory: databaseFactoryFfi,
      path: path,
    );
    const a = StudyDeck(deckId: 1, name: '아침', base: Cell.elementaryEasy);
    const b = StudyDeck(deckId: 2, name: '저녁', base: Cell.elementaryEasy);
    const book = Word(
      id: 'ee-002',
      word: 'book',
      meaning: '책',
      example: 'x',
      exampleMeaning: 'y',
    );

    await records.recordQuizAnswer(deck: a, word: word, correct: false);
    await records.recordQuizAnswer(deck: a, word: word, correct: false);
    await records.recordQuizAnswer(deck: a, word: book, correct: true);
    // b에서는 같은 단어를 맞힌 뒤 한 번 틀린다
    await records.recordQuizAnswer(deck: b, word: word, correct: true);
    await records.recordQuizAnswer(deck: b, word: book, correct: false);

    final notesA = await records.deckWrongNotes(a);
    expect(notesA.map((n) => (n.wordId, n.deck, n.missCount)), [
      ('ee-001', a, 2),
    ]);
    final notesB = await records.deckWrongNotes(b);
    expect(notesB.map((n) => (n.wordId, n.deck, n.missCount)), [
      ('ee-002', b, 1),
    ]);

    // 외운 수: a는 book(마지막 답 맞힘), b는 apple — b의 맞힘이 a의 apple을 외움으로 바꾸지 않는다
    final pa = await records.progress(a);
    final pb = await records.progress(b);
    expect((pa.memorized, pa.wrong), (1, 1));
    expect((pb.memorized, pb.wrong), (1, 1));
    expect(pa.days.map((d) => (d.cards, d.answered, d.correct)), [(0, 3, 1)]);
    expect(pb.days.map((d) => (d.cards, d.answered, d.correct)), [(0, 2, 1)]);

    // 한 단어장에서 빼도 다른 단어장의 같은 단어는 남는다
    await records.recordQuizAnswer(deck: b, word: word, correct: false);
    await records.removeWrongNote(a, 'ee-001');
    expect(await records.deckWrongNotes(a), isEmpty);
    expect(
      (await records.deckWrongNotes(b)).map((n) => n.wordId),
      containsAll(['ee-001', 'ee-002']),
    );
    // 칸 id로 쌓인 것이 없으므로 칸의 오답 노트에도 섞이지 않는다
    expect(await records.deckWrongNotes(Cell.elementaryEasy), isEmpty);
    await (await records.database).close();
  });

  test('지운 오답 노트를 되살리면 틀린 횟수와 처음·마지막 시각이 그대로이고, 그 사이 생긴 줄은 덮어쓴다', () async {
    final records = SqfliteStudyRecords(
      factory: databaseFactoryFfi,
      path: path,
    );
    const deck = StudyDeck(deckId: 1, name: '아침', base: Cell.elementaryEasy);
    const other = StudyDeck(deckId: 2, name: '저녁', base: Cell.elementaryEasy);
    await records.recordQuizAnswer(deck: deck, word: word, correct: false);
    await records.recordQuizAnswer(deck: deck, word: word, correct: false);
    await records.recordQuizAnswer(deck: other, word: word, correct: false);
    // 시각을 알아볼 수 있는 값으로 바꿔 둔다
    final db = await records.database;
    await db.update(
      'wrong_notes',
      {'first_missed_at': 1000, 'last_missed_at': 2000},
      where: 'cell_id = ?',
      whereArgs: [deck.id],
    );

    final before = (await records.deckWrongNotes(deck)).single;
    expect(
      (before.missCount, before.firstMissedAt, before.lastMissedAt),
      (2, 1000, 2000),
    );
    await records.removeWrongNote(deck, word.id);
    expect(await records.deckWrongNotes(deck), isEmpty);

    await records.restoreWrongNote(before);
    final after = (await records.deckWrongNotes(deck)).single;
    expect((after.wordId, after.missCount), (word.id, 2));
    expect((after.firstMissedAt, after.lastMissedAt), (1000, 2000));
    // 다른 단어장의 같은 단어는 건드리지 않는다
    expect((await records.deckWrongNotes(other)).single.missCount, 1);

    // 지운 사이에 다시 틀려 줄이 새로 생겼어도 되살린 값으로 덮어쓴다(줄이 둘이 되지 않는다)
    await records.removeWrongNote(deck, word.id);
    await records.recordQuizAnswer(deck: deck, word: word, correct: false);
    await records.restoreWrongNote(before);
    final again = await records.deckWrongNotes(deck);
    expect(again, hasLength(1));
    expect(again.single.missCount, 2);
    await db.close();
  });

  test('진행 일수는 처음 공부한 날을 1일로 치고 오늘까지 달력 날짜로 센다', () {
    Progress days(List<String> list) => Progress(
      days: [
        for (final d in list)
          DayStat(day: d, cards: 1, answered: 0, correct: 0),
      ],
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
