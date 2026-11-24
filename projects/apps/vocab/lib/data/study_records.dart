import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'cell.dart';
import 'word.dart';

/// 카드를 넘겨 본 기록·시험 기록(맞힘/틀림)과 오답 노트를 기기 안에 저장한다.
/// 시험(test)에서는 가짜로 바꾼다.
abstract interface class StudyRecords {
  /// 카드 하나를 넘겨 본 것을 남긴다. 오답 노트에는 넣지 않는다 — 카드 학습은 스스로 채점하지 않고,
  /// 오답 노트는 시험에서 틀린 단어만 담는다(2026-11-22 사용자 결정).
  /// `deck`은 칸 또는 이름 있는 단어장 — 기록의 `cell_id`에 `deck.id`가 들어간다.
  Future<void> recordCardViewed({required Deck deck, required Word word});

  /// `deck`에서 카드로 한 번이라도 넘겨 본 단어의 id. 카드 학습이 안 본 단어를 먼저 내는 데 쓴다.
  Future<Set<String>> viewedWordIds(Deck deck);

  /// 4지선다 한 문제의 결과를 남긴다. 틀리면(`correct == false`) 오답 노트에도 넣는다.
  /// 진도의 "외웠다"(시험에서 맞힘, 틀리면 해제)는 이 기록의 단어별 마지막 결과로 센다.
  Future<void> recordQuizAnswer({
    required Deck deck,
    required Word word,
    required bool correct,
  });

  /// 단어 묶음 하나(칸·이름 있는 단어장)의 오답 노트. 최근에 틀린 단어가 위.
  Future<List<WrongNote>> deckWrongNotes(Deck deck);

  /// 오답 노트에서 뺀다 — 오답 시험에서 맞혔거나 사용자가 지웠을 때(2026-11-20 사용자 결정).
  /// 같은 단어가 다른 단어장의 노트에도 있을 수 있어 `deck`의 것만 뺀다.
  /// 학습·시험 기록(`study_log`·`quiz_log`)은 그대로 둔다.
  Future<void> removeWrongNote(Deck deck, String wordId);

  /// 지운 오답 노트를 틀린 횟수·시각 그대로 되살린다(지우기의 "되돌리기" — 2026-11-22 사용자 결정(UX 점검)).
  /// 그 사이에 같은 단어가 다시 틀려 노트에 생겼으면 되살린 값으로 덮어쓴다.
  Future<void> restoreWrongNote(WrongNote note);

  /// 진도 화면에 쓸 집계: `deck` 하나의 외운 수·오답 수·날짜별 공부 수·맞힌 수.
  /// 진도는 지금 단어장 것만 보여 준다(2026-11-22 사용자 결정 — 같은 칸으로 만든 다른 단어장의
  /// 기록도 섞지 않는다).
  Future<Progress> progress(Deck deck);
}

/// 하루의 기록. `day`는 기기 시간대 `YYYY-MM-DD`.
class DayStat {
  const DayStat({
    required this.day,
    required this.cards,
    required this.answered,
    required this.correct,
  });

  final String day;

  /// 그날 넘겨 본 카드 수(카드 학습).
  final int cards;

  /// 그날 시험에서 답한 문제 수.
  final int answered;

  /// 그날 시험에서 맞힌 문제 수.
  final int correct;
}

/// 단어 묶음 하나의 진도 집계.
class Progress {
  const Progress({this.memorized = 0, this.wrong = 0, this.days = const []});

  /// 외운 단어 수. 외웠다 = 이 묶음에서 그 단어의 마지막 시험 답이 맞힘(틀리면 해제 — 명세).
  final int memorized;

  /// 오답 노트에 있는 단어 수.
  final int wrong;

  /// 공부한 날들. 최근 날짜가 앞.
  final List<DayStat> days;

  /// 진행 일수: 처음 공부한 날을 1일로 치고 `today`까지 달력 날짜로 센 날 수.
  /// 공부를 쉰 날도 센다. 기록이 없으면 0.
  /// (2026-11-22 사용자 결정 — 전에는 "연속 학습일"이었는데, 하루 쉬면 0일이 되어 어색하다는 지적)
  int elapsedDays(DateTime today) {
    if (days.isEmpty) return 0;
    final first = days
        .map((d) => d.day)
        .reduce((a, b) => a.compareTo(b) < 0 ? a : b);
    final parts = first.split('-').map(int.parse).toList();
    // 서머타임에 흔들리지 않게 UTC 날짜끼리 뺀다
    final start = DateTime.utc(parts[0], parts[1], parts[2]);
    final end = DateTime.utc(today.year, today.month, today.day);
    final diff = end.difference(start).inDays;
    // 기기 날짜를 과거로 돌린 경우에도 0 이하가 되지 않게 한다
    return diff < 0 ? 1 : diff + 1;
  }
}

/// 오답 노트의 한 단어.
class WrongNote {
  const WrongNote({
    required this.wordId,
    required this.deck,
    required this.missCount,
    required this.lastMissedAt,
    this.firstMissedAt,
  });

  final String wordId;

  /// 단어가 속한 칸 또는 이름 있는 단어장.
  final Deck deck;

  /// 틀린 횟수(시험에서 틀린 수 — 6판 이행 때 옛 카드 학습 '모른다'는 빼고 다시 셌다).
  final int missCount;

  /// 마지막으로 틀린 시각(밀리초).
  final int lastMissedAt;

  /// 처음 틀린 시각(밀리초). 되살릴 때 쓴다 — 모르면 null(되살릴 때 마지막 시각을 쓴다).
  final int? firstMissedAt;
}

/// 날짜별 집계용 키: 기기 시간대 기준 `YYYY-MM-DD`.
String dayKey(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}-'
    '${t.month.toString().padLeft(2, '0')}-'
    '${t.day.toString().padLeft(2, '0')}';

/// sqflite 구현. DB 파일은 앱 전용 폴더의 `vocab.db`.
///
/// - `study_log`: 카드를 넘겨 볼 때마다 한 줄(`known`은 늘 1, 옛 기록엔 0도 있다). 진도 화면의 칸별·날짜별 집계에 쓴다
///   (`answered_day`는 기기 시간대 날짜라 자정 경계가 어긋나지 않는다)
/// - `wrong_notes`: 단어 묶음(`cell_id`)마다 단어 하나에 한 줄(5판부터 기본 키 `(cell_id, word_id)` —
///   같은 칸으로 만든 단어장 둘이 같은 `word_id`를 쓰므로). 다시 틀리면 `miss_count`를 올리고
///   `last_missed_at`을 고친다. 시험에서 틀린 단어만 담는다(카드 학습은 담지 않음 — 2026-11-22 사용자 결정)
/// - `study_decks`: 이름 있는 단어장(5판, `study_decks.dart`의 `SqfliteStudyDecks`가 읽고 쓴다).
///   기록은 `cell_id = deck_<번호>`, `word_id`는 바탕 칸의 내장 단어 id(`w-0801` 등).
///   7판부터 단어장마다의 설정 `card_count`·`quiz_count`(NULL이면 옛 공통 설정을 물려받음)
/// - `app_meta`: 한 번만 하는 일의 표시(5판). 지금은 옛 칸 기록을 단어장으로 옮겼는지
class SqfliteStudyRecords implements StudyRecords {
  /// `factory`·`path`는 PC 시험에서 sqflite_common_ffi와 임시 파일을 넣을 때만 쓴다.
  SqfliteStudyRecords({this.factory, this.path});

  final DatabaseFactory? factory;
  final String? path;
  Future<Database>? _db;

  /// 연 DB. 처음 부를 때 한 번 열고 이후로는 같은 연결을 쓴다(이름 있는 단어장도 이것을 함께 쓴다).
  Future<Database> get database => _db ??= _open();

  Future<Database> get _database => database;

  /// 지금 DB 판. 1: study_log·wrong_notes, 2: quiz_log 추가(2026-11-20).
  /// 올릴 때는 onUpgrade에 `oldVersion < N` 단계를 더한다 — 몇 판에서 오든 차례로 올라간다.
  /// 3: 진도의 "단어별 마지막 시험 답"을 빨리 찾는 인덱스 `quiz_log(word_id, id)` 추가(2026-11-20).
  /// 4: 내 단어장 `word_books`·`book_words` 추가(2026-11-20).
  /// 5: 이름 있는 단어장 `study_decks`·`app_meta` 추가, `wrong_notes` 기본 키를 `(cell_id, word_id)`로,
  ///    단어별 마지막 시험 답 인덱스를 단어장별 `quiz_log(cell_id, word_id, id)`로(2026-11-22).
  /// 6: 시험에서 틀린 적 없는 오답 노트(옛 카드 '모른다')를 지우고 틀린 횟수를 시험 오답 수로 맞춤,
  ///    내 단어장 `word_books`·`book_words` 표와 `book_` 기록을 지움(2026-11-22 사용자 결정).
  /// 7: 단어장마다의 설정 `study_decks.card_count`·`quiz_count`(NULL 허용 — 7판 전 단어장은 NULL이고
  ///    옛 공통 설정을 물려받는다) 추가(2026-11-22 사용자 결정 — "설정은 그 단어장의 고유 설정이다").
  /// 8: 초등 단어를 새 번호(`w-0001`~)로 바꾸며 남은 옛 초등 번호(`ee-`·`em-`·`eh-`)의 학습·시험
  ///    기록과 오답 노트를 지움(2026-11-23 사용자 결정 — 진도만 옛 기록을 세어 홈·오답 노트와 어긋났다).
  /// 9: 중등 단어를 새 번호(`w-0801`~)로 바꾸며 옛 중등 번호(`me-`·`mm-`·`mh-`)의 학습·시험
  ///    기록과 오답 노트를 지움(2026-11-23 사용자 결정, docs/plan-words-phase2.md 3단계).
  /// 10: 고등 단어를 새 번호(`w-1501`~)로 바꾸며 옛 고등 번호(`he-`·`hm-`·`hh-`)의 학습·시험
  ///    기록과 오답 노트를 지움(docs/plan-words-phase3.md 3단계).
  static const int schemaVersion = 10;

  Future<Database> _open() async {
    final dbFactory = factory ?? databaseFactory;
    final dbPath =
        path ?? p.join(await dbFactory.getDatabasesPath(), 'vocab.db');
    return dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        // 새로 설치해도 올라오는 사용자와 같은 단계를 밟는다 — 5판 이행이 한 길로만 검증되게.
        // 4판의 내 단어장 표는 6판에서 지우므로 새 설치는 만들지 않는다
        onCreate: (db, version) async {
          await createV3(db);
          await _upgradeToV5(db);
          await _upgradeToV6(db);
          await _upgradeToV7(db);
          // 8·9·10판은 옛 기록을 지울 뿐이라 새 설치에는 할 일이 없다
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) await _createQuizLog(db);
          if (oldVersion < 3) await _createQuizWordIndex(db);
          if (oldVersion < 4) await _createWordBooks(db);
          if (oldVersion < 5) await _upgradeToV5(db);
          if (oldVersion < 6) await _upgradeToV6(db);
          if (oldVersion < 7) await _upgradeToV7(db);
          if (oldVersion < 8) await upgradeToV8(db);
          if (oldVersion < 9) await upgradeToV9(db);
          if (oldVersion < 10) await _upgradeToV10(db);
        },
      ),
    );
  }

  /// 4판까지의 표. 시험에서 "4판 사용자"의 DB를 만들 때도 쓴다 — 5판 이후의 표는 여기에 더하지 않는다.
  @visibleForTesting
  static Future<void> createV4(Database db) async {
    await createV3(db);
    await _createWordBooks(db);
  }

  /// 5판까지의 표. 시험에서 "5판 사용자"의 DB를 만들 때 쓴다 — 6판 이후의 변경은 여기에 더하지 않는다.
  @visibleForTesting
  static Future<void> createV5(Database db) async {
    await createV4(db);
    await _upgradeToV5(db);
  }

  /// 6판까지의 표. 시험에서 "6판 사용자"의 DB를 만들 때 쓴다 — 7판 이후의 변경은 여기에 더하지 않는다.
  @visibleForTesting
  static Future<void> createV6(Database db) async {
    await createV5(db);
    await _upgradeToV6(db);
  }

  /// 7판까지의 표. 시험에서 "7판 사용자"의 DB를 만들 때 쓴다 — 8판 이후의 변경은 여기에 더하지 않는다.
  @visibleForTesting
  static Future<void> createV7(Database db) async {
    await createV6(db);
    await _upgradeToV7(db);
  }

  /// 8판까지의 표. 시험에서 "8판 사용자"의 DB를 만들 때 쓴다 — 9판 이후의 변경은 여기에 더하지 않는다.
  @visibleForTesting
  static Future<void> createV8(Database db) async {
    await createV7(db);
    await upgradeToV8(db);
  }

  /// 9판까지의 표. 시험에서 "9판 사용자"의 DB를 만들 때 쓴다 — 10판 이후의 변경은 여기에 더하지 않는다.
  @visibleForTesting
  static Future<void> createV9(Database db) async {
    await createV8(db);
    await upgradeToV9(db);
  }

  /// 9판: 옛 중등 번호의 기록을 지운다(2026-11-23 사용자 결정 — "그 칸의 기존 50개씩을 지우고
  /// CEFR-J로", docs/plan-words-phase2.md). 중등 3칸의 단어를 CEFR-J 700개로 바꾸며 번호가
  /// `me-001`·`mm-001`·`mh-001` 꼴에서 `w-0801` 꼴로 바뀌어, 옛 번호의 기록은 어느 단어와도
  /// 이어지지 않는다. 8판과 같이 어느 단어장·칸의 것이든 지우고, 단어장(`study_decks`) 줄은 남긴다.
  /// 초등(`w-`) 번호와 고등 번호는 건드리지 않는다(옛 고등 번호는 10판에서 지운다).
  /// 시험에서 8→9판 이행만 따로 확인할 수 있게 공개한다.
  @visibleForTesting
  static Future<void> upgradeToV9(Database db) =>
      _deleteWordIds(db, const ['me-', 'mm-', 'mh-']);

  /// 10판: 옛 고등 번호의 기록을 지운다(docs/plan-words-phase3.md). 고등 3칸의 단어를 1,500개로
  /// 바꾸며 번호가 `he-001`·`hm-001`·`hh-001` 꼴에서 `w-1501` 꼴로 바뀌어, 옛 번호의 기록은 어느
  /// 단어와도 이어지지 않는다. 8·9판과 같이 어느 단어장·칸의 것이든 지우고, 단어장(`study_decks`)
  /// 줄은 남긴다. 이로써 옛 번호(`[emh][emh]-`)의 기록은 모두 사라진다.
  static Future<void> _upgradeToV10(Database db) =>
      _deleteWordIds(db, const ['he-', 'hm-', 'hh-']);

  /// 세 기록 표에서 `word_id`가 주어진 앞붙이로 시작하는 줄을 지운다(8·9·10판 공통).
  static Future<void> _deleteWordIds(Database db, List<String> prefixes) async {
    final where = prefixes.map((p) => "word_id LIKE '$p%'").join(' OR ');
    for (final table in const ['study_log', 'quiz_log', 'wrong_notes']) {
      await db.delete(table, where: where);
    }
  }

  /// 8판: 옛 초등 번호의 기록을 지운다(2026-11-23 사용자 결정). 초등 3칸의 단어를 CEFR-J 800개로
  /// 바꾸며 번호가 `ee-001`·`em-001`·`eh-001` 꼴에서 `w-0001` 꼴로 바뀌어, 옛 번호의 기록은 어느
  /// 단어와도 이어지지 않는다 — 오답 노트 화면에는 안 보이는데 진도의 외운 수·오답 수에는 세어졌다.
  /// 어느 단어장·칸의 것이든 지운다(그 날짜의 공부 기록도 함께 사라지고, 그 단어장의 진행 일수는
  /// 남은 기록 기준으로 다시 센다 — 남은 것이 없으면 "아직 시작하지 않았습니다"). 중등·고등 번호는
  /// 여기서 건드리지 않는다 — 그 칸의 단어를 바꿀 때 같은 단계를 새 판으로 더했다(중등 9판, 고등 10판).
  /// 시험에서 7→8판 이행만 따로 확인할 수 있게 공개한다.
  @visibleForTesting
  static Future<void> upgradeToV8(Database db) =>
      _deleteWordIds(db, const ['ee-', 'em-', 'eh-']);

  /// 7판: 단어장마다의 설정(2026-11-22 사용자 결정). 새로 만드는 단어장은 기본값을 넣고,
  /// 7판 전에 있던 단어장은 NULL로 두어 옛 공통 설정을 물려받는다(`app_settings.dart`).
  /// 단어장 줄을 지우면 설정도 함께 사라진다. 새 설치도 이 단계를 밟아 표 정의가 같다.
  static Future<void> _upgradeToV7(Database db) async {
    await db.execute('ALTER TABLE study_decks ADD COLUMN card_count INTEGER');
    await db.execute('ALTER TABLE study_decks ADD COLUMN quiz_count INTEGER');
  }

  /// 5판: 이름 있는 단어장(2026-11-22 사용자 결정 — 같은 학교급+난이도로 여러 개, 기록은 따로).
  /// onUpgrade는 트랜잭션 안에서 돌아 중간에 끊겨도 4판 그대로 남는다.
  static Future<void> _upgradeToV5(Database db) async {
    await db.execute('''
      CREATE TABLE study_decks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        cell_id TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE app_meta(
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )''');
    // 기본 키가 word_id 하나면 같은 칸으로 만든 단어장 둘의 오답이 한 줄로 겹친다 — 줄은 모두 옮긴다
    await db.execute('''
      CREATE TABLE wrong_notes_v5(
        word_id TEXT NOT NULL,
        cell_id TEXT NOT NULL,
        miss_count INTEGER NOT NULL,
        first_missed_at INTEGER NOT NULL,
        last_missed_at INTEGER NOT NULL,
        PRIMARY KEY (cell_id, word_id)
      )''');
    await db.execute(
      'INSERT INTO wrong_notes_v5 '
      '(word_id, cell_id, miss_count, first_missed_at, last_missed_at) '
      'SELECT word_id, cell_id, miss_count, first_missed_at, last_missed_at '
      'FROM wrong_notes',
    );
    await db.execute('DROP TABLE wrong_notes');
    await db.execute('ALTER TABLE wrong_notes_v5 RENAME TO wrong_notes');
    // "외웠다"는 단어장마다 그 단어의 마지막 시험 답 — 찾는 조건에 cell_id가 붙는다
    await db.execute('DROP INDEX IF EXISTS quiz_log_word');
    await db.execute(
      'CREATE INDEX quiz_log_deck_word ON quiz_log(cell_id, word_id, id)',
    );
  }

  /// 6판(2026-11-22 사용자 결정): 오답 노트는 시험에서 틀린 단어만 — 옛 카드 학습 '모른다'로
  /// 들어간 줄을 지우고, 남은 줄의 틀린 횟수와 마지막으로 틀린 시각을 시험 오답 기준으로 맞춘다.
  /// 세는 것은 **지금 노트가 생긴 뒤(`first_missed_at` 이후)의 시험 오답만**이다 — 오답 시험에서 맞혀
  /// 빠지기 전의 오답은 지금 노트의 것이 아니다. 기록과 노트는 같은 시각(ms)으로 쓰므로 노트를 만든
  /// 시험 오답도 들어간다. 기기 시계를 되돌린 적이 있으면 어긋날 수 있다.
  /// 직접 단어를 넣는 내 단어장은 기능째 지웠으므로 표와 `book_` 기록을 지운다.
  /// 등록하지 않았던 칸의 옛 기록(칸 id 그대로인 줄)은 `study_log`·`quiz_log`는 건드리지 않고,
  /// 오답 노트만 위 정리를 똑같이 받는다(이 시점에는 등록한 칸의 줄도 칸 id라 가를 수 없다).
  /// onUpgrade는 트랜잭션 안에서 돌아 중간에 끊겨도 옛 판 그대로 남는다.
  static Future<void> _upgradeToV6(Database db) async {
    // `book_`은 LIKE로 쓰면 `_`가 아무 글자이므로 앞 5글자를 그대로 비교한다
    for (final table in ['study_log', 'quiz_log', 'wrong_notes']) {
      await db.execute(
        "DELETE FROM $table WHERE substr(cell_id, 1, 5) = 'book_'",
      );
    }
    await db.execute('DROP INDEX IF EXISTS book_words_book');
    await db.execute('DROP TABLE IF EXISTS book_words');
    await db.execute('DROP TABLE IF EXISTS word_books');
    // 지금 노트가 생긴 뒤에 그 단어장 시험에서 틀린 답
    const missesSinceNote =
        'FROM quiz_log q WHERE q.cell_id = wrong_notes.cell_id '
        'AND q.word_id = wrong_notes.word_id AND q.correct = 0 '
        'AND q.answered_at >= wrong_notes.first_missed_at';
    await db.execute(
      'DELETE FROM wrong_notes WHERE NOT EXISTS (SELECT 1 $missesSinceNote)',
    );
    await db.execute(
      'UPDATE wrong_notes SET '
      'miss_count = (SELECT COUNT(*) $missesSinceNote), '
      'last_missed_at = (SELECT MAX(q.answered_at) $missesSinceNote)',
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

  /// 4판의 내 단어장 표. 6판에서 지우지만, 옛 판에서 차례로 올라오는 단계와 "4판 사용자" 시험 DB가
  /// 4판 그대로의 모양을 갖도록 남겨 둔다.
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
  Future<Progress> progress(Deck deck) async {
    final db = await _database;
    // 그 단어장에서 단어별 마지막 시험 답은 id가 가장 큰 줄 — 시각은 같거나 기기 시계가 바뀔 수 있어
    // 쓰지 않는다. 같은 칸으로 만든 다른 단어장의 답은 보지 않는다(같은 word_id라도 cell_id가 다르다)
    final memorizedRows = await db.rawQuery(
      'SELECT COUNT(*) AS n FROM quiz_log q '
      'WHERE cell_id = ? AND correct = 1 AND id = '
      '(SELECT MAX(id) FROM quiz_log '
      'WHERE cell_id = q.cell_id AND word_id = q.word_id)',
      [deck.id],
    );
    final wrongRows = await db.rawQuery(
      'SELECT COUNT(*) AS n FROM wrong_notes WHERE cell_id = ?',
      [deck.id],
    );
    // 카드 수와 시험 답 수를 따로 센다(2026-11-22 사용자 결정(UX 점검) — 화면에 따로 보인다)
    final dayRows = await db.rawQuery(
      'SELECT day, SUM(cards) AS cards, SUM(answered) AS answered, '
      'SUM(correct) AS correct FROM ('
      'SELECT answered_day AS day, COUNT(*) AS cards, 0 AS answered, '
      '0 AS correct FROM study_log WHERE cell_id = ? GROUP BY answered_day '
      'UNION ALL '
      'SELECT answered_day AS day, 0 AS cards, COUNT(*) AS answered, '
      'SUM(correct) AS correct '
      'FROM quiz_log WHERE cell_id = ? GROUP BY answered_day'
      ') GROUP BY day ORDER BY day DESC',
      [deck.id, deck.id],
    );

    return Progress(
      memorized: memorizedRows.single['n'] as int,
      wrong: wrongRows.single['n'] as int,
      days: [
        for (final row in dayRows)
          DayStat(
            day: row['day'] as String,
            cards: row['cards'] as int,
            answered: row['answered'] as int,
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
  Future<void> recordCardViewed({required Deck deck, required Word word}) =>
      // `known` 열은 옛 '안다' 기록 때문에 남겨 둔다(DB 이행을 피함) — 이제는 늘 1
      _record('study_log', 'known', deck: deck, word: word, ok: true);

  @override
  Future<Set<String>> viewedWordIds(Deck deck) async {
    final db = await _database;
    final rows = await db.rawQuery(
      'SELECT DISTINCT word_id FROM study_log WHERE cell_id = ?',
      [deck.id],
    );
    return {for (final row in rows) row['word_id'] as String};
  }

  @override
  Future<void> recordQuizAnswer({
    required Deck deck,
    required Word word,
    required bool correct,
  }) => _record('quiz_log', 'correct', deck: deck, word: word, ok: correct);

  @override
  Future<List<WrongNote>> deckWrongNotes(Deck deck) async {
    final db = await _database;
    final rows = await db.query(
      'wrong_notes',
      where: 'cell_id = ?',
      whereArgs: [deck.id],
      orderBy: 'last_missed_at DESC, word_id',
    );
    return [
      for (final row in rows)
        WrongNote(
          wordId: row['word_id'] as String,
          deck: deck,
          missCount: row['miss_count'] as int,
          lastMissedAt: row['last_missed_at'] as int,
          firstMissedAt: row['first_missed_at'] as int,
        ),
    ];
  }

  @override
  Future<void> restoreWrongNote(WrongNote note) async {
    final db = await _database;
    await db.insert('wrong_notes', {
      'word_id': note.wordId,
      'cell_id': note.deck.id,
      'miss_count': note.missCount,
      'first_missed_at': note.firstMissedAt ?? note.lastMissedAt,
      'last_missed_at': note.lastMissedAt,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> removeWrongNote(Deck deck, String wordId) async {
    final db = await _database;
    await db.delete(
      'wrong_notes',
      where: 'cell_id = ? AND word_id = ?',
      whereArgs: [deck.id, wordId],
    );
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
        // 안드로이드 옛 SQLite에는 UPSERT가 없어 UPDATE 뒤 없으면 INSERT 한다.
        // 같은 단어가 다른 단어장의 노트에 있어도 이 단어장 줄만 고친다
        final updated = await txn.rawUpdate(
          'UPDATE wrong_notes SET miss_count = miss_count + 1, '
          'last_missed_at = ? WHERE cell_id = ? AND word_id = ?',
          [ms, deck.id, word.id],
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

/// 앱의 sqflite DB(`vocab.db`) 하나. 학습 기록과 이름 있는 단어장(`studyDecksProvider`)이 이 객체를 함께 써
/// DB 연결·판이 하나로 유지된다.
final vocabDatabaseProvider = Provider<SqfliteStudyRecords>(
  (ref) => SqfliteStudyRecords(),
);

final studyRecordsProvider = Provider<StudyRecords>(
  (ref) => ref.watch(vocabDatabaseProvider),
);

/// 단어장 하나에서 카드로 넘겨 본 단어 id. 카드 학습을 열 때마다 새로 읽는다(autoDispose).
final viewedWordIdsProvider = FutureProvider.autoDispose
    .family<Set<String>, Deck>(
      (ref, deck) => ref.watch(studyRecordsProvider).viewedWordIds(deck),
    );

/// 단어장 하나의 진도 집계(외운 수·오답 수·날짜별 기록 모두 그 단어장 것만).
/// 진도 화면을 열 때마다 새로 읽는다(autoDispose).
final progressProvider = FutureProvider.autoDispose.family<Progress, Deck>(
  (ref, deck) => ref.watch(studyRecordsProvider).progress(deck),
);

/// 단어장 하나의 오답 노트(최근에 틀린 것이 위). 화면을 열 때마다 새로 읽는다(autoDispose).
/// 홈·단어장 화면·오답 노트 화면은 안쪽 화면에서 돌아오면 이것을 invalidate 해 다시 읽는다.
final deckWrongNotesProvider = FutureProvider.autoDispose
    .family<List<WrongNote>, Deck>(
      (ref, deck) => ref.watch(studyRecordsProvider).deckWrongNotes(deck),
    );
