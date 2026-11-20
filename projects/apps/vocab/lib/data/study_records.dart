import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'cell.dart';
import 'word.dart';

/// 학습 기록(안다/모른다)·시험 기록(맞힘/틀림)과 오답 노트를 기기 안에 저장한다.
/// 시험(test)에서는 가짜로 바꾼다.
abstract interface class StudyRecords {
  /// 카드 하나에 답한 것을 남긴다. 모른다(`known == false`)면 오답 노트에도 넣는다.
  /// `deck`은 칸 또는 내 단어장 — 기록의 `cell_id`에 `deck.id`가 들어간다.
  Future<void> recordAnswer({
    required Deck deck,
    required Word word,
    required bool known,
  });

  /// 4지선다 한 문제의 결과를 남긴다. 틀리면(`correct == false`) 오답 노트에도 넣는다.
  /// 진도의 "외웠다"(시험에서 맞힘, 틀리면 해제)는 이 기록의 단어별 마지막 결과로 센다.
  Future<void> recordQuizAnswer({
    required Deck deck,
    required Word word,
    required bool correct,
  });

  /// 학교급의 오답 노트(내장 칸만). 최근에 틀린 단어가 위.
  Future<List<WrongNote>> wrongNotes(SchoolLevel level);

  /// 내 단어장 하나의 오답 노트. 최근에 틀린 단어가 위.
  Future<List<WrongNote>> bookWrongNotes(BookDeck book);

  /// 오답 노트에서 뺀다 — 오답 시험에서 맞혔거나 사용자가 지웠을 때(2026-11-20 사용자 결정).
  /// 학습·시험 기록(`study_log`·`quiz_log`)은 그대로 둔다.
  Future<void> removeWrongNote(String wordId);

  /// 진도 화면에 쓸 집계(난이도별 외운 수·오답 수, 날짜별 공부 수·맞힌 수).
  /// 내장 9칸의 기록만 센다 — 내 단어장 기록은 들어가지 않는다.
  Future<Progress> progress();
}

/// 하루의 기록. `day`는 기기 시간대 `YYYY-MM-DD`.
class DayStat {
  const DayStat({
    required this.day,
    required this.studied,
    required this.correct,
  });

  final String day;

  /// 그날 답한 횟수(카드 학습 + 시험).
  final int studied;

  /// 그날 시험에서 맞힌 횟수.
  final int correct;
}

/// 진도 집계.
class Progress {
  const Progress({
    this.memorized = const {},
    this.wrong = const {},
    this.days = const [],
  });

  /// 외운 단어 수. 외웠다 = 그 단어의 마지막 시험 답이 맞힘(틀리면 해제 — 명세).
  final Map<Cell, int> memorized;

  /// 오답 노트에 있는 단어 수.
  final Map<Cell, int> wrong;

  /// 공부한 날들. 최근 날짜가 앞.
  final List<DayStat> days;

  /// 연속 학습일: `today`(없으면 어제)부터 거슬러 올라가며 하루도 빠지지 않은 날 수.
  /// 오늘 아직 안 했어도 어제까지 이어졌으면 끊긴 것으로 보지 않는다.
  int streak(DateTime today) {
    final done = {for (final d in days) d.day};
    var day = DateTime(today.year, today.month, today.day);
    if (!done.contains(dayKey(day))) {
      day = DateTime(day.year, day.month, day.day - 1);
    }
    var count = 0;
    while (done.contains(dayKey(day))) {
      count++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return count;
  }
}

/// 오답 노트의 한 단어.
class WrongNote {
  const WrongNote({
    required this.wordId,
    required this.deck,
    required this.missCount,
    required this.lastMissedAt,
  });

  final String wordId;

  /// 단어가 속한 칸 또는 내 단어장.
  final Deck deck;

  /// 모른다·틀림을 받은 횟수.
  final int missCount;

  /// 마지막으로 틀린 시각(밀리초).
  final int lastMissedAt;
}

/// 날짜별 집계용 키: 기기 시간대 기준 `YYYY-MM-DD`.
String dayKey(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}-'
    '${t.month.toString().padLeft(2, '0')}-'
    '${t.day.toString().padLeft(2, '0')}';

/// sqflite 구현. DB 파일은 앱 전용 폴더의 `vocab.db`.
///
/// - `study_log`: 답할 때마다 한 줄. 진도 화면의 칸별·날짜별 집계에 쓴다
///   (`answered_day`는 기기 시간대 날짜라 자정 경계가 어긋나지 않는다)
/// - `wrong_notes`: 단어 하나에 한 줄. 다시 모른다고 하면 `miss_count`를 올리고
///   `last_missed_at`을 고친다. '안다'로 답해도 지우지 않는다 — 빼는 방법은 오답 노트 화면에서 정한다.
///   `word_id`는 칸 머리글자가 붙어(예: ee-001) 칸이 달라도 겹치지 않는다(단어 파일 검사 시험)
/// - `word_books`·`book_words`: 내 단어장과 그 단어(4판). 읽고 쓰는 것은 `SqfliteWordBooks`
///   (`word_books.dart`)가 이 객체의 [database]로 한다 — DB 파일·연결·판은 여기 하나다.
///   내 단어장 기록은 `cell_id`가 `book_<번호>`, `word_id`가 `bw-<번호>`라 내장 단어와 겹치지 않는다
class SqfliteStudyRecords implements StudyRecords {
  /// `factory`·`path`는 PC 시험에서 sqflite_common_ffi와 임시 파일을 넣을 때만 쓴다.
  SqfliteStudyRecords({this.factory, this.path});

  final DatabaseFactory? factory;
  final String? path;
  Future<Database>? _db;

  /// 연 DB. 처음 부를 때 한 번 열고 이후로는 같은 연결을 쓴다(내 단어장도 이것을 함께 쓴다).
  Future<Database> get database => _db ??= _open();

  Future<Database> get _database => database;

  /// 지금 DB 판. 1: study_log·wrong_notes, 2: quiz_log 추가(2026-11-20).
  /// 올릴 때는 onUpgrade에 `oldVersion < N` 단계를 더한다 — 몇 판에서 오든 차례로 올라간다.
  /// 3: 진도의 "단어별 마지막 시험 답"을 빨리 찾는 인덱스 `quiz_log(word_id, id)` 추가(2026-11-20).
  /// 4: 내 단어장 `word_books`·`book_words` 추가(2026-11-20).
  static const int schemaVersion = 4;

  Future<Database> _open() async {
    final dbFactory = factory ?? databaseFactory;
    final dbPath =
        path ?? p.join(await dbFactory.getDatabasesPath(), 'vocab.db');
    return dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onCreate: (db, version) async {
          await createV3(db);
          await _createWordBooks(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) await _createQuizLog(db);
          if (oldVersion < 3) await _createQuizWordIndex(db);
          if (oldVersion < 4) await _createWordBooks(db);
        },
      ),
    );
  }

  /// 3판까지의 표. 시험에서 "3판 사용자"의 DB를 만들 때도 쓴다 — 4판 이후의 표는 여기에 더하지 않는다.
  @visibleForTesting
  static Future<void> createV3(Database db) async {
    await createV1(db);
    await _createQuizLog(db);
    await _createQuizWordIndex(db);
  }

  /// 시험 한 문제마다 한 줄. `correct` 1 = 맞힘.
  static Future<void> _createQuizWordIndex(Database db) =>
      db.execute('CREATE INDEX quiz_log_word ON quiz_log(word_id, id)');

  /// 내 단어장(4판). 예문·해석은 선택이라 비어 있으면 빈 문자열.
  static Future<void> _createWordBooks(Database db) async {
    await db.execute('''
      CREATE TABLE word_books(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE book_words(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id INTEGER NOT NULL,
        word TEXT NOT NULL,
        meaning TEXT NOT NULL,
        example TEXT NOT NULL DEFAULT '',
        example_meaning TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL
      )''');
    await db.execute('CREATE INDEX book_words_book ON book_words(book_id)');
  }

  @override
  Future<Progress> progress() async {
    final db = await _database;
    // 단어별 마지막 시험 답은 id가 가장 큰 줄 — 시각은 같거나 기기 시계가 바뀔 수 있어 쓰지 않는다
    final memorizedRows = await db.rawQuery(
      'SELECT cell_id, COUNT(*) AS n FROM quiz_log q '
      'WHERE correct = 1 AND id = '
      '(SELECT MAX(id) FROM quiz_log WHERE word_id = q.word_id) '
      'GROUP BY cell_id',
    );
    final wrongRows = await db.rawQuery(
      'SELECT cell_id, COUNT(*) AS n FROM wrong_notes GROUP BY cell_id',
    );
    // 진도는 내장 9칸만 센다 — 내 단어장(`book_N`) 기록은 날짜별 집계에서도 뺀다
    final cellIds = [for (final c in Cell.values) c.id];
    final inCells =
        'cell_id IN (${List.filled(cellIds.length, '?').join(', ')})';
    final dayRows = await db.rawQuery(
      'SELECT day, SUM(n) AS studied, SUM(c) AS correct FROM ('
      'SELECT answered_day AS day, COUNT(*) AS n, 0 AS c '
      'FROM study_log WHERE $inCells GROUP BY answered_day '
      'UNION ALL '
      'SELECT answered_day AS day, COUNT(*) AS n, SUM(correct) AS c '
      'FROM quiz_log WHERE $inCells GROUP BY answered_day'
      ') GROUP BY day ORDER BY day DESC',
      [...cellIds, ...cellIds],
    );
    Map<Cell, int> byCell(List<Map<String, Object?>> rows) {
      final result = <Cell, int>{};
      for (final row in rows) {
        final cell = Cell.byId(row['cell_id'] as String);
        if (cell != null) result[cell] = row['n'] as int; // 모르는 칸 id는 건너뛴다
      }
      return result;
    }

    return Progress(
      memorized: byCell(memorizedRows),
      wrong: byCell(wrongRows),
      days: [
        for (final row in dayRows)
          DayStat(
            day: row['day'] as String,
            studied: row['studied'] as int,
            correct: row['correct'] as int,
          ),
      ],
    );
  }

  static Future<void> _createQuizLog(Database db) async {
    await db.execute('''
      CREATE TABLE quiz_log(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word_id TEXT NOT NULL,
        cell_id TEXT NOT NULL,
        correct INTEGER NOT NULL,
        answered_at INTEGER NOT NULL,
        answered_day TEXT NOT NULL
      )''');
    await db.execute(
      'CREATE INDEX quiz_log_cell_day ON quiz_log(cell_id, answered_day)',
    );
  }

  /// 1판 표. 시험에서 "1판 사용자"의 DB를 만들 때도 쓴다.
  @visibleForTesting
  static Future<void> createV1(Database db) async {
    await db.execute('''
          CREATE TABLE study_log(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            word_id TEXT NOT NULL,
            cell_id TEXT NOT NULL,
            known INTEGER NOT NULL,
            answered_at INTEGER NOT NULL,
            answered_day TEXT NOT NULL
          )''');
    await db.execute(
      'CREATE INDEX study_log_cell_day ON study_log(cell_id, answered_day)',
    );
    await db.execute('''
          CREATE TABLE wrong_notes(
            word_id TEXT PRIMARY KEY,
            cell_id TEXT NOT NULL,
            miss_count INTEGER NOT NULL,
            first_missed_at INTEGER NOT NULL,
            last_missed_at INTEGER NOT NULL
          )''');
  }

  @override
  Future<void> recordAnswer({
    required Deck deck,
    required Word word,
    required bool known,
  }) => _record('study_log', 'known', deck: deck, word: word, ok: known);

  @override
  Future<void> recordQuizAnswer({
    required Deck deck,
    required Word word,
    required bool correct,
  }) => _record('quiz_log', 'correct', deck: deck, word: word, ok: correct);

  @override
  Future<List<WrongNote>> wrongNotes(SchoolLevel level) async {
    final db = await _database;
    final cells = [
      for (final c in Cell.values)
        if (c.level == level) c,
    ];
    final rows = await db.query(
      'wrong_notes',
      where: 'cell_id IN (${List.filled(cells.length, '?').join(', ')})',
      whereArgs: [for (final c in cells) c.id],
      orderBy: 'last_missed_at DESC, word_id',
    );
    return [
      for (final row in rows)
        if (Cell.byId(row['cell_id'] as String) case final cell?)
          WrongNote(
            wordId: row['word_id'] as String,
            deck: cell,
            missCount: row['miss_count'] as int,
            lastMissedAt: row['last_missed_at'] as int,
          ),
    ];
  }

  @override
  Future<List<WrongNote>> bookWrongNotes(BookDeck book) async {
    final db = await _database;
    final rows = await db.query(
      'wrong_notes',
      where: 'cell_id = ?',
      whereArgs: [book.id],
      orderBy: 'last_missed_at DESC, word_id',
    );
    return [
      for (final row in rows)
        WrongNote(
          wordId: row['word_id'] as String,
          deck: book,
          missCount: row['miss_count'] as int,
          lastMissedAt: row['last_missed_at'] as int,
        ),
    ];
  }

  @override
  Future<void> removeWrongNote(String wordId) async {
    final db = await _database;
    await db.delete('wrong_notes', where: 'word_id = ?', whereArgs: [wordId]);
  }

  /// 기록 표에 한 줄 넣고, 실패(`ok == false`)면 오답 노트에도 넣는다.
  Future<void> _record(
    String table,
    String okColumn, {
    required Deck deck,
    required Word word,
    required bool ok,
  }) async {
    final db = await _database;
    final now = DateTime.now();
    final ms = now.millisecondsSinceEpoch;
    await db.transaction((txn) async {
      await txn.insert(table, {
        'word_id': word.id,
        'cell_id': deck.id,
        okColumn: ok ? 1 : 0,
        'answered_at': ms,
        'answered_day': dayKey(now),
      });
      if (!ok) {
        // 안드로이드 옛 SQLite에는 UPSERT가 없어 UPDATE 뒤 없으면 INSERT 한다
        final updated = await txn.rawUpdate(
          'UPDATE wrong_notes SET miss_count = miss_count + 1, '
          'last_missed_at = ? WHERE word_id = ?',
          [ms, word.id],
        );
        if (updated == 0) {
          await txn.insert('wrong_notes', {
            'word_id': word.id,
            'cell_id': deck.id,
            'miss_count': 1,
            'first_missed_at': ms,
            'last_missed_at': ms,
          });
        }
      }
    });
  }
}

/// 앱의 sqflite DB(`vocab.db`) 하나. 학습 기록과 내 단어장(`wordBooksProvider`)이 이 객체를 함께 써
/// DB 연결·판이 하나로 유지된다.
final vocabDatabaseProvider = Provider<SqfliteStudyRecords>(
  (ref) => SqfliteStudyRecords(),
);

final studyRecordsProvider = Provider<StudyRecords>(
  (ref) => ref.watch(vocabDatabaseProvider),
);

/// 진도 집계. 진도 화면을 열 때마다 새로 읽는다(autoDispose).
final progressProvider = FutureProvider.autoDispose<Progress>(
  (ref) => ref.watch(studyRecordsProvider).progress(),
);

/// 칸 또는 내 단어장 하나의 오답 노트(최근에 틀린 것이 위). 화면을 열 때마다 새로 읽는다(autoDispose).
/// 칸 홈·단어장 화면·오답 노트 화면은 안쪽 화면에서 돌아오면 이것을 invalidate 해 다시 읽는다.
final deckWrongNotesProvider = FutureProvider.autoDispose
    .family<List<WrongNote>, Deck>((ref, deck) async {
      final records = ref.watch(studyRecordsProvider);
      return switch (deck) {
        Cell() => [
          for (final n in await records.wrongNotes(deck.level))
            if (n.deck == deck) n,
        ],
        BookDeck() => records.bookWrongNotes(deck),
      };
    });
