import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cell.dart';

/// 지금 고른 단어장 번호를 기기에 남긴다. 시험에서는 가짜로 바꾼다.
/// 앱을 열면 이 단어장의 홈으로 바로 간다(2026-11-20 사용자 결정, 2026-11-22부터 칸 대신 단어장).
///
/// 이름 있는 단어장이 생기기 전 버전은 고른 칸(키 `cell`)과 등록한 칸 목록(키 `registered_cells`)을
/// 남겼다. 그 둘은 옛 기록을 단어장으로 옮길 때 읽기만 하고 그대로 둔다(`study_decks.dart`).
abstract interface class CellStore {
  /// 지금 고른 단어장 번호(`StudyDeck.deckId`). 처음 실행이면 null.
  Future<int?> loadSelectedDeck();

  Future<void> saveSelectedDeck(int deckId);

  /// 옛 버전에서 마지막에 고른 칸. 없거나 모르는 값이면 null.
  Future<Cell?> loadLegacyCell();

  /// 옛 버전에서 등록한 칸들(등록한 순서). 없으면 빈 목록.
  Future<List<Cell>> loadLegacyRegistered();
}

/// shared_preferences 구현.
class PrefsCellStore implements CellStore {
  static const _selectedDeckKey = 'selected_deck';
  static const _legacyCellKey = 'cell';
  static const _legacyRegisteredKey = 'registered_cells';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  @override
  Future<int?> loadSelectedDeck() => _prefs.getInt(_selectedDeckKey);

  @override
  Future<void> saveSelectedDeck(int deckId) =>
      _prefs.setInt(_selectedDeckKey, deckId);

  @override
  Future<Cell?> loadLegacyCell() async {
    final id = await _prefs.getString(_legacyCellKey);
    return id == null ? null : Cell.byId(id);
  }

  @override
  Future<List<Cell>> loadLegacyRegistered() async {
    final ids = await _prefs.getStringList(_legacyRegisteredKey) ?? const [];
    return [for (final id in ids) ?Cell.byId(id)]; // 모르는 id는 건너뛴다
  }
}

final cellStoreProvider = Provider<CellStore>((ref) => PrefsCellStore());
