import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cell.dart';

/// 마지막에 고른 칸(학교급 + 난이도)을 기기에 남긴다. 시험에서는 가짜로 바꾼다.
/// 앱을 열면 이 칸의 홈으로 바로 간다(2026-11-20 사용자 결정).
abstract interface class CellStore {
  /// 저장된 칸. 처음 실행이거나 모르는 값이면 null.
  Future<Cell?> load();

  Future<void> save(Cell cell);

  /// 등록한 칸들(☰ 메뉴에 보이는 목록, 등록한 순서). 없으면 빈 목록.
  Future<List<Cell>> loadRegistered();

  Future<void> saveRegistered(List<Cell> cells);
}

/// shared_preferences 구현. 값은 칸 id(`middle_medium` 등) 하나.
class PrefsCellStore implements CellStore {
  static const _key = 'cell';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  @override
  Future<Cell?> load() async {
    final id = await _prefs.getString(_key);
    return id == null ? null : Cell.byId(id);
  }

  @override
  Future<void> save(Cell cell) => _prefs.setString(_key, cell.id);

  static const _registeredKey = 'registered_cells';

  @override
  Future<List<Cell>> loadRegistered() async {
    final ids = await _prefs.getStringList(_registeredKey) ?? const [];
    return [for (final id in ids) ?Cell.byId(id)]; // 모르는 id는 건너뛴다
  }

  @override
  Future<void> saveRegistered(List<Cell> cells) =>
      _prefs.setStringList(_registeredKey, [for (final c in cells) c.id]);
}

final cellStoreProvider = Provider<CellStore>((ref) => PrefsCellStore());

/// 지금 고른 칸. null이면 아직 고르지 않았다(첫 실행).
class SelectedCell extends AsyncNotifier<Cell?> {
  @override
  Future<Cell?> build() => ref.read(cellStoreProvider).load();

  /// 화면에는 바로 반영하고 기기에 저장한다. 저장이 실패하면 예외를 그대로 낸다 —
  /// 이번 실행에서는 고른 칸으로 쓰고, 화면이 실패를 알린다.
  Future<void> select(Cell cell) async {
    state = AsyncData(cell);
    await ref.read(cellStoreProvider).save(cell);
  }
}

final selectedCellProvider = AsyncNotifierProvider<SelectedCell, Cell?>(
  SelectedCell.new,
);

/// 등록한 칸 목록(2026-11-22 사용자 결정 — ☰ 메뉴에는 등록한 학교급+난이도만 보인다.
/// 홈 오른쪽 아래 동그란 버튼으로 학교급 → 난이도를 골라 등록한다).
class RegisteredCells extends AsyncNotifier<List<Cell>> {
  @override
  Future<List<Cell>> build() async {
    final store = ref.read(cellStoreProvider);
    final list = await store.loadRegistered();
    if (list.isNotEmpty) return list;
    // 등록 목록이 생기기 전 버전에서 고른 칸이 있으면 그것을 등록된 것으로 본다
    final selected = await store.load();
    return [?selected];
  }

  /// 목록 끝에 더한다(이미 있으면 그대로). 화면에는 바로 반영하고 기기에 저장한다 —
  /// 저장이 실패하면 예외를 그대로 낸다.
  Future<void> add(Cell cell) async {
    final current = await future;
    if (current.contains(cell)) return;
    final next = [...current, cell];
    state = AsyncData(next);
    await ref.read(cellStoreProvider).saveRegistered(next);
  }
}

final registeredCellsProvider =
    AsyncNotifierProvider<RegisteredCells, List<Cell>>(RegisteredCells.new);
