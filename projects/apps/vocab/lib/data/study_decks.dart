import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cell.dart';
import 'counts.dart';
import 'cell_store.dart';
import 'study_records.dart';

/// 옛 칸 기록을 옮겨 만든 단어장의 이름. 예: `중등 중간`.
String legacyDeckName(Cell cell) =>
    '${cell.level.label} ${cell.difficulty.label}';

/// 단어장 하나의 고유 설정(7판 `card_count`·`quiz_count`). null이면 저장된 값이 없다 —
/// 7판 전에 있던 단어장이거나 없는 단어장. 범위 확인과 물려받기는 `app_settings.dart`가 한다.
typedef DeckCounts = ({int? cardCount, int? quizCount});

/// 이름 있는 단어장(2026-11-22 사용자 결정 — "새 등록"은 무조건 새 단어장, 이름을 짓고
/// 학교급 → 난이도를 고른다. 같은 학교급+난이도도 여러 개). 시험(test)에서는 가짜로 바꾼다.
abstract interface class StudyDecks {
  /// 만든 순서대로.
  Future<List<StudyDeck>> decks();

  /// 새 단어장은 설정 기본값(카드 [defaultCardCount]·시험 [defaultQuizCount])을 명시적으로 저장한다 —
  /// 옛 공통 설정을 물려받지 않는다(2026-11-22 사용자 결정).
  Future<StudyDeck> createDeck(String name, Cell base);

  Future<void> renameDeck(int deckId, String name);

  /// 단어장의 고유 설정. 저장된 값이 없으면(7판 전 단어장·없는 단어장) 그 값이 null.
  Future<DeckCounts> loadCounts(int deckId);

  Future<void> saveCardCount(int deckId, int count);

  Future<void> saveQuizCount(int deckId, int count);

  /// 단어장과 그 오답 노트·학습·시험 기록(`wrong_notes`·`study_log`·`quiz_log`)을 지운다
  /// (2026-11-22 사용자 결정). 다른 단어장·칸 id의 줄은 건드리지 않는다.
  Future<void> deleteDeck(int deckId);

  /// 옛 버전(칸 id로 기록을 쌓던 때)의 기록을 단어장으로 옮긴다. 한 번만 한다.
  ///
  /// `cells`마다(같은 칸은 한 번) 단어장을 하나 만들고(이름은 [legacyDeckName]) 그 칸의
  /// `study_log`·`quiz_log`·`wrong_notes` 줄을 새 단어장 id로 옮긴다. `selected` 칸으로 만든
  /// 단어장 번호를 돌려준다(없으면 null). 이미 옮겼으면 아무것도 하지 않고 그때 돌려준 번호를
  /// 다시 돌려준다 — 옮긴 뒤 고른 단어장 저장이 끊겼어도 다음 실행에서 이어 저장하게.
  Future<int?> migrateLegacy({required List<Cell> cells, Cell? selected});
}

/// sqflite 구현. 학습 기록과 같은 DB 연결([SqfliteStudyRecords.database])을 쓴다 —
/// 표는 그쪽의 5판에서 만든다.
class SqfliteStudyDecks implements StudyDecks {
  SqfliteStudyDecks(this._owner);

  final SqfliteStudyRecords _owner;

  /// `app_meta`에 남기는 "옛 칸 기록을 옮겼다" 표시. 값은 고른 칸으로 만든 단어장 번호(없으면 빈 문자열).
  static const migratedKey = 'legacy_cells_migrated';

  @override
  Future<List<StudyDeck>> decks() async {
    final db = await _owner.database;
    final rows = await db.query('study_decks', orderBy: 'id');
    return [
      for (final row in rows)
        if (Cell.byId(row['cell_id'] as String) case final base?) // 모르는 칸은 건너뛴다
          StudyDeck(
            deckId: row['id'] as int,
            name: row['name'] as String,
            base: base,
          ),
    ];
  }

  @override
  Future<StudyDeck> createDeck(String name, Cell base) async {
    final db = await _owner.database;
    final id = await db.insert('study_decks', {
      'name': name,
      'cell_id': base.id,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'card_count': defaultCardCount,
      'quiz_count': defaultQuizCount,
    });
    return StudyDeck(deckId: id, name: name, base: base);
  }

  @override
  Future<DeckCounts> loadCounts(int deckId) async {
    final db = await _owner.database;
    final rows = await db.query(
      'study_decks',
      columns: ['card_count', 'quiz_count'],
      where: 'id = ?',
      whereArgs: [deckId],
    );
    if (rows.isEmpty) return (cardCount: null, quizCount: null);
    return (
      cardCount: rows.single['card_count'] as int?,
      quizCount: rows.single['quiz_count'] as int?,
    );
  }

  @override
  Future<void> saveCardCount(int deckId, int count) =>
      _saveCount(deckId, 'card_count', count);

  @override
  Future<void> saveQuizCount(int deckId, int count) =>
      _saveCount(deckId, 'quiz_count', count);

  Future<void> _saveCount(int deckId, String column, int count) async {
    final db = await _owner.database;
    await db.update(
      'study_decks',
      {column: count},
      where: 'id = ?',
      whereArgs: [deckId],
    );
  }

  @override
  Future<void> renameDeck(int deckId, String name) async {
    final db = await _owner.database;
    await db.update(
      'study_decks',
      {'name': name},
      where: 'id = ?',
      whereArgs: [deckId],
    );
  }

  @override
  Future<void> deleteDeck(int deckId) async {
    final db = await _owner.database;
    await db.transaction((txn) async {
      for (final table in const ['wrong_notes', 'study_log', 'quiz_log']) {
        await txn.delete(
          table,
          where: 'cell_id = ?',
          whereArgs: [StudyDeck.idOf(deckId)],
        );
      }
      await txn.delete('study_decks', where: 'id = ?', whereArgs: [deckId]);
    });
  }

  @override
  Future<int?> migrateLegacy({
    required List<Cell> cells,
    Cell? selected,
  }) async {
    final db = await _owner.database;
    // 한 트랜잭션: 중간에 끊기면 아무것도 바뀌지 않아 다음 실행에서 처음부터 다시 한다
    return db.transaction((txn) async {
      final done = await txn.query(
        'app_meta',
        where: 'key = ?',
        whereArgs: [migratedKey],
      );
      if (done.isNotEmpty) return int.tryParse(done.single['value'] as String);

      int? selectedDeck;
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final cell in cells.toSet()) {
        final id = await txn.insert('study_decks', {
          'name': legacyDeckName(cell),
          'cell_id': cell.id,
          'created_at': now,
        });
        final deckId = StudyDeck.idOf(id);
        // 그 칸의 첫 단어장이 지금까지의 기록을 이어받는다(사용자 승인)
        for (final table in const ['study_log', 'quiz_log', 'wrong_notes']) {
          await txn.update(
            table,
            {'cell_id': deckId},
            where: 'cell_id = ?',
            whereArgs: [cell.id],
          );
        }
        if (cell == selected) selectedDeck = id;
      }
      await txn.insert('app_meta', {
        'key': migratedKey,
        'value': selectedDeck?.toString() ?? '',
      });
      return selectedDeck;
    });
  }
}

final studyDecksProvider = Provider<StudyDecks>(
  (ref) => SqfliteStudyDecks(ref.watch(vocabDatabaseProvider)),
);

/// 내 단어장 목록과 지금 고른 것. `current`가 null이면 단어장이 하나도 없다(시작 화면).
class DeckList {
  const DeckList({required this.decks, this.current});

  final List<StudyDeck> decks;
  final StudyDeck? current;
}

/// 단어장 목록과 고른 단어장. 처음 읽을 때 옛 칸 기록을 단어장으로 옮긴다(한 번만).
class DeckListNotifier extends AsyncNotifier<DeckList> {
  @override
  Future<DeckList> build() async {
    final store = ref.read(cellStoreProvider);
    final repo = ref.read(studyDecksProvider);

    // 옛 버전 사용자: 등록한 칸마다(목록이 비어 있으면 고른 칸 하나) 단어장을 만들어 기록을 옮긴다
    final legacyCell = await store.loadLegacyCell();
    final legacyCells = await store.loadLegacyRegistered();
    final migrated = await repo.migrateLegacy(
      cells: [...legacyCells, ?legacyCell],
      selected: legacyCell,
    );

    var selectedId = await store.loadSelectedDeck();
    if (selectedId == null && migrated != null) {
      selectedId = migrated;
      try {
        await store.saveSelectedDeck(migrated);
      } catch (_) {
        // 이번 실행에서는 옮긴 단어장을 고른 것으로 쓴다 — 다음 실행에서 다시 저장해 본다
      }
    }
    final decks = await repo.decks();
    return DeckList(
      decks: decks,
      current: _find(decks, selectedId) ?? decks.firstOrNull,
    );
  }

  static StudyDeck? _find(List<StudyDeck> decks, int? id) {
    for (final d in decks) {
      if (d.deckId == id) return d;
    }
    return null;
  }

  /// 새 단어장을 만들고 고른다. 만들기에 실패하면 예외를 그대로 낸다(아무것도 바뀌지 않음).
  /// 고른 것 저장이 실패하면 [DeckSelectionNotSaved]를 낸다 — 이번 실행에서는 새 단어장으로 쓴다.
  Future<StudyDeck> create(String name, Cell base) async {
    final current = await future;
    final deck = await ref.read(studyDecksProvider).createDeck(name, base);
    state = AsyncData(DeckList(decks: [...current.decks, deck], current: deck));
    await _saveSelected(deck);
    return deck;
  }

  /// 화면에는 바로 반영하고 기기에 저장한다. 저장이 실패하면 [DeckSelectionNotSaved]를 낸다.
  Future<void> select(StudyDeck deck) async {
    final current = await future;
    state = AsyncData(DeckList(decks: current.decks, current: deck));
    await _saveSelected(deck);
  }

  Future<void> rename(StudyDeck deck, String name) async {
    await ref.read(studyDecksProvider).renameDeck(deck.deckId, name);
    final current = await future;
    final renamed = deck.renamed(name);
    state = AsyncData(
      DeckList(
        decks: [for (final d in current.decks) d == deck ? renamed : d],
        current: current.current == deck ? renamed : current.current,
      ),
    );
  }

  /// 지운다. 지금 고른 것을 지우면 남은 것 중 맨 위를 고르고, 하나도 없으면 시작 화면이 된다.
  Future<void> delete(StudyDeck deck) async {
    await ref.read(studyDecksProvider).deleteDeck(deck.deckId);
    final current = await future;
    final rest = [
      for (final d in current.decks)
        if (d != deck) d,
    ];
    final next = current.current == deck ? rest.firstOrNull : current.current;
    state = AsyncData(DeckList(decks: rest, current: next));
    if (next != null && next != current.current) await _saveSelected(next);
  }

  Future<void> _saveSelected(StudyDeck deck) async {
    try {
      await ref.read(cellStoreProvider).saveSelectedDeck(deck.deckId);
    } catch (_) {
      throw const DeckSelectionNotSaved();
    }
  }
}

/// 고른 단어장을 기기에 저장하지 못했다(이번 실행에서는 고른 것으로 쓴다).
class DeckSelectionNotSaved implements Exception {
  const DeckSelectionNotSaved();
}

final deckListProvider = AsyncNotifierProvider<DeckListNotifier, DeckList>(
  DeckListNotifier.new,
);
