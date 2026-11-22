import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cell.dart';
import 'study_records.dart';
import 'word.dart';

/// 내 단어장 하나(목록에 보이는 것).
class WordBook {
  const WordBook({
    required this.id,
    required this.name,
    required this.wordCount,
  });

  final int id;
  final String name;
  final int wordCount;

  /// 카드 학습·시험·오답 노트에 넘기는 묶음.
  BookDeck get deck => BookDeck(bookId: id, name: name);
}

/// 내 단어장 단어의 id. 내장 단어(`ee-001` 등)와 겹치지 않게 `bw-`를 붙인다.
String bookWordId(int rowId) => 'bw-$rowId';

/// 내 단어장 — 여러 개 만들고 단어(영단어 + 뜻 필수, 예문·해석 선택)를 넣는다(명세).
/// 시험(test)에서는 가짜로 바꾼다.
abstract interface class WordBooks {
  /// 만든 순서대로, 단어 수와 함께.
  Future<List<WordBook>> books();

  /// 번호로 하나. 없으면(지워졌으면) null.
  Future<WordBook?> book(int id);

  /// 새로 만들고 번호를 돌려준다.
  Future<int> createBook(String name);

  Future<void> renameBook(int id, String name);

  /// 단어장과 그 단어, 그 단어장의 오답 노트를 지운다. 학습·시험 기록(`study_log`·`quiz_log`)은 남긴다.
  Future<void> deleteBook(int id);

  /// 단어장의 단어. 넣은 순서(카드 학습은 이 순서 그대로 — 내장 칸의 파일 순서와 같은 규칙).
  Future<List<Word>> words(int bookId);

  /// 예문·해석이 없으면 빈 문자열을 넣는다.
  Future<void> addWord(
    int bookId, {
    required String word,
    required String meaning,
    String example = '',
    String exampleMeaning = '',
  });

  /// `word.id`(`bw-N`)의 내용을 바꾼다. 오답 노트·기록은 id로 가리키므로 그대로 이어진다.
  Future<void> updateWord(Word word);

  /// 단어와 그 단어의 오답 노트를 지운다. 학습·시험 기록은 남긴다.
  Future<void> deleteWord(String wordId);
}

/// sqflite 구현. 학습 기록과 같은 DB 연결([SqfliteStudyRecords.database])을 쓴다 —
/// 표는 그쪽의 4판에서 만든다.
class SqfliteWordBooks implements WordBooks {
  SqfliteWordBooks(this._owner);

  final SqfliteStudyRecords _owner;

  @override
  Future<List<WordBook>> books() async {
    final db = await _owner.database;
    final rows = await db.rawQuery(
      'SELECT b.id, b.name, COUNT(w.id) AS n FROM word_books b '
      'LEFT JOIN book_words w ON w.book_id = b.id '
      'GROUP BY b.id ORDER BY b.id',
    );
    return [for (final row in rows) _book(row)];
  }

  @override
  Future<WordBook?> book(int id) async {
    final db = await _owner.database;
    final rows = await db.rawQuery(
      'SELECT b.id, b.name, COUNT(w.id) AS n FROM word_books b '
      'LEFT JOIN book_words w ON w.book_id = b.id '
      'WHERE b.id = ? GROUP BY b.id',
      [id],
    );
    return rows.isEmpty ? null : _book(rows.single);
  }

  static WordBook _book(Map<String, Object?> row) => WordBook(
    id: row['id'] as int,
    name: row['name'] as String,
    wordCount: row['n'] as int,
  );

  @override
  Future<int> createBook(String name) async {
    final db = await _owner.database;
    return db.insert('word_books', {
      'name': name,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<void> renameBook(int id, String name) async {
    final db = await _owner.database;
    await db.update(
      'word_books',
      {'name': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteBook(int id) async {
    final db = await _owner.database;
    await db.transaction((txn) async {
      await txn.delete(
        'wrong_notes',
        where: 'cell_id = ?',
        whereArgs: [BookDeck(bookId: id, name: '').id],
      );
      await txn.delete('book_words', where: 'book_id = ?', whereArgs: [id]);
      await txn.delete('word_books', where: 'id = ?', whereArgs: [id]);
    });
  }

  @override
  Future<List<Word>> words(int bookId) async {
    final db = await _owner.database;
    final rows = await db.query(
      'book_words',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'id',
    );
    return [
      for (final row in rows)
        Word(
          id: bookWordId(row['id'] as int),
          word: row['word'] as String,
          meaning: row['meaning'] as String,
          example: row['example'] as String,
          exampleMeaning: row['example_meaning'] as String,
        ),
    ];
  }

  @override
  Future<void> addWord(
    int bookId, {
    required String word,
    required String meaning,
    String example = '',
    String exampleMeaning = '',
  }) async {
    final db = await _owner.database;
    await db.insert('book_words', {
      'book_id': bookId,
      'word': word,
      'meaning': meaning,
      'example': example,
      'example_meaning': exampleMeaning,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<void> updateWord(Word word) async {
    final db = await _owner.database;
    await db.update(
      'book_words',
      {
        'word': word.word,
        'meaning': word.meaning,
        'example': word.example,
        'example_meaning': word.exampleMeaning,
      },
      where: 'id = ?',
      whereArgs: [_rowId(word.id)],
    );
  }

  @override
  Future<void> deleteWord(String wordId) async {
    final db = await _owner.database;
    await db.transaction((txn) async {
      // 오답 노트의 기본 키는 (cell_id, word_id)(5판) — 그 단어가 든 단어장의 줄만 지운다
      final owner = await txn.query(
        'book_words',
        columns: ['book_id'],
        where: 'id = ?',
        whereArgs: [_rowId(wordId)],
      );
      if (owner.isNotEmpty) {
        await txn.delete(
          'wrong_notes',
          where: 'cell_id = ? AND word_id = ?',
          whereArgs: [
            BookDeck(bookId: owner.single['book_id'] as int, name: '').id,
            wordId,
          ],
        );
      }
      await txn.delete(
        'book_words',
        where: 'id = ?',
        whereArgs: [_rowId(wordId)],
      );
    });
  }

  /// `bw-12` → 12.
  static int _rowId(String wordId) => int.parse(wordId.substring(3));
}

final wordBooksProvider = Provider<WordBooks>(
  (ref) => SqfliteWordBooks(ref.watch(vocabDatabaseProvider)),
);

/// 단어장 목록. 화면을 열 때마다, 또 단어장 화면에서 돌아올 때 다시 읽는다(autoDispose + invalidate).
final wordBookListProvider = FutureProvider.autoDispose<List<WordBook>>(
  (ref) => ref.watch(wordBooksProvider).books(),
);

/// 단어장 하나(이름·단어 수). 없으면 null.
final wordBookProvider = FutureProvider.autoDispose.family<WordBook?, int>(
  (ref, id) => ref.watch(wordBooksProvider).book(id),
);

/// 단어장의 단어(넣은 순서). 단어를 더하거나 고치면 invalidate 한다.
final bookWordsProvider = FutureProvider.autoDispose.family<List<Word>, int>(
  (ref, id) => ref.watch(wordBooksProvider).words(id),
);
