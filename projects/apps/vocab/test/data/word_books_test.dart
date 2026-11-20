import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vocab/data/cell.dart';
import 'package:vocab/data/study_records.dart';
import 'package:vocab/data/word.dart';
import 'package:vocab/data/word_books.dart';

/// 내 단어장을 실제 sqflite 구현(PC에서는 sqflite_common_ffi)으로 시험한다. DB는 임시 폴더의 파일.
/// 학습 기록과 내 단어장은 같은 DB 연결(SqfliteStudyRecords)을 함께 쓴다.
void main() {
  late Directory dir;
  late String path;
  late SqfliteStudyRecords records;
  late SqfliteWordBooks books;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('vocab_books_test');
    path = p.join(dir.path, 'vocab.db');
    records = SqfliteStudyRecords(factory: databaseFactoryFfi, path: path);
    books = SqfliteWordBooks(records);
  });

  tearDown(() async {
    // 임시 폴더를 지울 수 있게 DB를 닫는다(같은 파일은 연결 하나를 함께 쓴다)
    await (await databaseFactoryFfi.openDatabase(path)).close();
    await dir.delete(recursive: true);
  });

  Future<List<String>> names(Database db, String type) async => [
    for (final row in await db.rawQuery(
      'SELECT name FROM sqlite_master WHERE type = ? '
      "AND name NOT LIKE 'sqlite_%' ORDER BY name",
      [type],
    ))
      row['name'] as String,
  ];

  test('3판 사용자의 DB는 기록을 그대로 둔 채 4판(내 단어장 표)으로 올라간다', () async {
    final v3 = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (db, _) => SqfliteStudyRecords.createV3(db),
      ),
    );
    final row = {
      'word_id': 'ee-001',
      'cell_id': 'elementary_easy',
      'answered_at': 1,
      'answered_day': '2026-11-20',
    };
    await v3.insert('study_log', {...row, 'known': 0});
    await v3.insert('quiz_log', {...row, 'correct': 1});
    await v3.insert('wrong_notes', {
      'word_id': 'ee-001',
      'cell_id': 'elementary_easy',
      'miss_count': 1,
      'first_missed_at': 1,
      'last_missed_at': 1,
    });
    await v3.close();

    // 단어장을 쓰는 순간 같은 연결이 열리며 4판으로 올라간다
    final id = await books.createBook('여행 영어');
    expect((await books.books()).map((b) => (b.id, b.name, b.wordCount)), [
      (id, '여행 영어', 0),
    ]);

    final db = await records.database;
    expect(await db.getVersion(), 4);
    expect(SqfliteStudyRecords.schemaVersion, 4);
    expect(
      await names(db, 'table'),
      containsAll(['word_books', 'book_words', 'study_log', 'quiz_log']),
    );
    expect(await names(db, 'index'), contains('book_words_book'));
    expect(await db.rawQuery('SELECT word_id, known FROM study_log'), [
      {'word_id': 'ee-001', 'known': 0},
    ]);
    expect(await db.rawQuery('SELECT word_id, correct FROM quiz_log'), [
      {'word_id': 'ee-001', 'correct': 1},
    ]);
    expect(
      (await records.wrongNotes(SchoolLevel.elementary)).map((n) => n.wordId),
      ['ee-001'],
    );
  });

  test('새로 설치하면 내 단어장 표가 함께 생긴다', () async {
    await records.progress(); // 기록 쪽에서 먼저 열어도 같은 DB·같은 판
    final db = await records.database;
    expect(await db.getVersion(), SqfliteStudyRecords.schemaVersion);
    expect(
      await names(db, 'table'),
      containsAll(['word_books', 'book_words', 'wrong_notes']),
    );
  });

  test('단어장을 만들고 이름을 바꾸며, 단어를 넣은 순서대로 읽고 고치고 지운다', () async {
    final a = await books.createBook('A');
    final b = await books.createBook('B');
    await books.renameBook(a, '동물');

    await books.addWord(a, word: 'cat', meaning: '고양이');
    await books.addWord(
      a,
      word: 'dog',
      meaning: '개',
      example: 'I have a dog.',
      exampleMeaning: '나는 개가 있다.',
    );
    await books.addWord(b, word: 'sun', meaning: '해');

    expect((await books.books()).map((x) => (x.id, x.name, x.wordCount)), [
      (a, '동물', 2),
      (b, 'B', 1),
    ]);
    final book = await books.book(a);
    expect((book!.name, book.wordCount), ('동물', 2));
    expect(book.deck, BookDeck(bookId: a, name: '동물'));
    expect(await books.book(999), isNull);

    final words = await books.words(a);
    expect(words.map((w) => (w.word, w.meaning, w.example, w.exampleMeaning)), [
      ('cat', '고양이', '', ''), // 예문·해석은 선택 — 없으면 빈 문자열
      ('dog', '개', 'I have a dog.', '나는 개가 있다.'),
    ]);
    expect(words.every((w) => w.id.startsWith('bw-')), isTrue);

    // 고치면 같은 id로 내용만 바뀐다
    await books.updateWord(
      Word(
        id: words[0].id,
        word: 'kitten',
        meaning: '새끼 고양이',
        example: 'A kitten sleeps.',
        exampleMeaning: '새끼 고양이가 잔다.',
      ),
    );
    final edited = (await books.words(a)).first;
    expect(
      (edited.id, edited.word, edited.meaning, edited.example),
      (words[0].id, 'kitten', '새끼 고양이', 'A kitten sleeps.'),
    );

    // 단어를 지우면 그 단어의 오답 노트도 지우고, 학습 기록은 남긴다
    final deck = BookDeck(bookId: a, name: '동물');
    await records.recordAnswer(deck: deck, word: words[1], known: false);
    expect((await records.bookWrongNotes(deck)).map((n) => n.wordId), [
      words[1].id,
    ]);
    await books.deleteWord(words[1].id);
    expect((await books.words(a)).map((w) => w.word), ['kitten']);
    expect(await records.bookWrongNotes(deck), isEmpty);
    final db = await records.database;
    expect(await db.rawQuery('SELECT word_id FROM study_log'), [
      {'word_id': words[1].id},
    ]);
  });

  test('단어장을 지우면 그 단어와 오답 노트만 지우고, 학습·시험 기록과 다른 단어장은 남긴다', () async {
    final a = await books.createBook('지울 것');
    final b = await books.createBook('남길 것');
    await books.addWord(a, word: 'cat', meaning: '고양이');
    await books.addWord(b, word: 'sun', meaning: '해');
    final deckA = BookDeck(bookId: a, name: '지울 것');
    final deckB = BookDeck(bookId: b, name: '남길 것');
    final cat = (await books.words(a)).single;
    final sun = (await books.words(b)).single;
    const apple = Word(
      id: 'ee-001',
      word: 'apple',
      meaning: '사과',
      example: 'x',
      exampleMeaning: 'y',
    );

    await records.recordQuizAnswer(deck: deckA, word: cat, correct: false);
    await records.recordAnswer(deck: deckA, word: cat, known: false);
    await records.recordQuizAnswer(deck: deckB, word: sun, correct: false);
    await records.recordAnswer(
      deck: Cell.elementaryEasy,
      word: apple,
      known: false,
    );

    await books.deleteBook(a);

    expect((await books.books()).map((x) => x.id), [b]);
    expect(await books.book(a), isNull);
    expect(await books.words(a), isEmpty);
    expect(await records.bookWrongNotes(deckA), isEmpty);
    expect((await records.bookWrongNotes(deckB)).map((n) => n.wordId), [
      sun.id,
    ]);
    expect(
      (await records.wrongNotes(SchoolLevel.elementary)).map((n) => n.wordId),
      ['ee-001'],
    );
    final db = await records.database;
    expect(
      await db.rawQuery(
        'SELECT COUNT(*) AS n FROM book_words WHERE book_id = ?',
        [a],
      ),
      [
        {'n': 0},
      ],
    );
    expect(
      await db.rawQuery(
        'SELECT word_id FROM quiz_log WHERE cell_id = ? ORDER BY id',
        [deckA.id],
      ),
      [
        {'word_id': cat.id},
      ],
      reason: '단어장을 지워도 시험 기록은 남는다',
    );
    expect(
      await db.rawQuery('SELECT word_id FROM study_log WHERE cell_id = ?', [
        deckA.id,
      ]),
      [
        {'word_id': cat.id},
      ],
      reason: '단어장을 지워도 학습 기록은 남는다',
    );
  });

  test('내 단어장 답은 book_<번호>·bw-<번호>로 기록되고, 진도와 학교급 오답 노트에는 섞이지 않는다', () async {
    final id = await books.createBook('내 것');
    await books.addWord(id, word: 'cat', meaning: '고양이');
    await books.addWord(id, word: 'dog', meaning: '개');
    final deck = (await books.book(id))!.deck;
    final [cat, dog] = await books.words(id);

    await records.recordQuizAnswer(deck: deck, word: cat, correct: true);
    await records.recordQuizAnswer(deck: deck, word: dog, correct: false);
    await records.recordAnswer(deck: deck, word: cat, known: false);

    final db = await records.database;
    expect(
      await db.rawQuery('SELECT word_id, cell_id FROM quiz_log ORDER BY id'),
      [
        {'word_id': 'bw-1', 'cell_id': 'book_$id'},
        {'word_id': 'bw-2', 'cell_id': 'book_$id'},
      ],
    );
    expect(await db.rawQuery('SELECT word_id, cell_id FROM study_log'), [
      {'word_id': 'bw-1', 'cell_id': 'book_$id'},
    ]);
    expect(Cell.byId(deck.id), isNull);

    // 단어장의 오답 노트에는 들어가고(최근에 틀린 것이 위)
    expect((await records.bookWrongNotes(deck)).map((n) => n.wordId), [
      'bw-1',
      'bw-2',
    ]);
    // 진도(외운 수·오답 수·날짜별)와 학교급 오답 노트에는 나오지 않는다
    final progress = await records.progress();
    expect(progress.memorized, isEmpty);
    expect(progress.wrong, isEmpty);
    expect(progress.days, isEmpty);
    for (final level in SchoolLevel.values) {
      expect(await records.wrongNotes(level), isEmpty);
    }
  });
}
