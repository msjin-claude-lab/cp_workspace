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
  Future<void> recordAnswer({
    required Cell cell,
    required Word word,
    required bool known,
  });

  /// 4지선다 한 문제의 결과를 남긴다. 틀리면(`correct == false`) 오답 노트에도 넣는다.
  /// 진도의 "외웠다"(시험에서 맞힘, 틀리면 해제)는 이 기록의 단어별 마지막 결과로 센다.
  Future<void> recordQuizAnswer({
    required Cell cell,
    required Word word,
    required bool correct,
  });
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
class SqfliteStudyRecords implements StudyRecords {
  /// `factory`·`path`는 PC 시험에서 sqflite_common_ffi와 임시 파일을 넣을 때만 쓴다.
  SqfliteStudyRecords({this.factory, this.path});

  final DatabaseFactory? factory;
  final String? path;
  Future<Database>? _db;

  Future<Database> get _database => _db ??= _open();

  /// 지금 DB 판. 1: study_log·wrong_notes, 2: quiz_log 추가(2026-11-20).
  /// 올릴 때는 onUpgrade에 `oldVersion < N` 단계를 더한다 — 몇 판에서 오든 차례로 올라간다.
  static const int schemaVersion = 2;

  Future<Database> _open() async {
    final dbFactory = factory ?? databaseFactory;
    final dbPath =
        path ?? p.join(await dbFactory.getDatabasesPath(), 'vocab.db');
    return dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onCreate: (db, version) async {
          await createV1(db);
          await _createQuizLog(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) await _createQuizLog(db);
        },
      ),
    );
  }

  /// 시험 한 문제마다 한 줄. `correct` 1 = 맞힘.
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
    required Cell cell,
    required Word word,
    required bool known,
  }) => _record('study_log', 'known', cell: cell, word: word, ok: known);

  @override
  Future<void> recordQuizAnswer({
    required Cell cell,
    required Word word,
    required bool correct,
  }) => _record('quiz_log', 'correct', cell: cell, word: word, ok: correct);

  /// 기록 표에 한 줄 넣고, 실패(`ok == false`)면 오답 노트에도 넣는다.
  Future<void> _record(
    String table,
    String okColumn, {
    required Cell cell,
    required Word word,
    required bool ok,
  }) async {
    final db = await _database;
    final now = DateTime.now();
    final ms = now.millisecondsSinceEpoch;
    await db.transaction((txn) async {
      await txn.insert(table, {
        'word_id': word.id,
        'cell_id': cell.id,
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
            'cell_id': cell.id,
            'miss_count': 1,
            'first_missed_at': ms,
            'last_missed_at': ms,
          });
        }
      }
    });
  }
}

final studyRecordsProvider = Provider<StudyRecords>(
  (ref) => SqfliteStudyRecords(),
);
