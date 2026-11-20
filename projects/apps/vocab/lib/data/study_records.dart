import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'cell.dart';
import 'word.dart';

/// 학습 기록(안다/모른다)과 오답 노트를 기기 안에 저장한다. 시험에서는 가짜로 바꾼다.
abstract interface class StudyRecords {
  /// 카드 하나에 답한 것을 남긴다. 모른다(`known == false`)면 오답 노트에도 넣는다.
  Future<void> recordAnswer(
      {required Cell cell, required Word word, required bool known});
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
  Future<Database>? _db;

  Future<Database> get _database => _db ??= _open();

  static Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, 'vocab.db'),
      version: 1,
      onCreate: (db, version) async {
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
            'CREATE INDEX study_log_cell_day ON study_log(cell_id, answered_day)');
        await db.execute('''
          CREATE TABLE wrong_notes(
            word_id TEXT PRIMARY KEY,
            cell_id TEXT NOT NULL,
            miss_count INTEGER NOT NULL,
            first_missed_at INTEGER NOT NULL,
            last_missed_at INTEGER NOT NULL
          )''');
      },
    );
  }

  @override
  Future<void> recordAnswer(
      {required Cell cell, required Word word, required bool known}) async {
    final db = await _database;
    final now = DateTime.now();
    final ms = now.millisecondsSinceEpoch;
    await db.transaction((txn) async {
      await txn.insert('study_log', {
        'word_id': word.id,
        'cell_id': cell.id,
        'known': known ? 1 : 0,
        'answered_at': ms,
        'answered_day': dayKey(now),
      });
      if (!known) {
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

final studyRecordsProvider =
    Provider<StudyRecords>((ref) => SqfliteStudyRecords());
