import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cell.dart';

/// 사용자가 고른 학교급을 기기에 남긴다. 시험에서는 가짜로 바꾼다.
abstract interface class LevelStore {
  /// 저장된 학교급. 처음 실행이면 null.
  Future<SchoolLevel?> load();

  Future<void> save(SchoolLevel level);
}

/// shared_preferences 구현. 값은 학교급 이름(`elementary` 등) 하나.
class PrefsLevelStore implements LevelStore {
  static const _key = 'school_level';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  @override
  Future<SchoolLevel?> load() async {
    final name = await _prefs.getString(_key);
    for (final level in SchoolLevel.values) {
      if (level.name == name) return level;
    }
    return null; // 없거나 모르는 값이면 처음 실행처럼 다시 고르게 한다
  }

  @override
  Future<void> save(SchoolLevel level) => _prefs.setString(_key, level.name);
}

final levelStoreProvider = Provider<LevelStore>((ref) => PrefsLevelStore());

/// 지금 고른 학교급. null이면 아직 고르지 않았다(첫 실행).
/// 앱을 켤 때 저장된 값을 읽고, 바꾸면 저장한 뒤 화면에 반영한다.
class SelectedLevel extends AsyncNotifier<SchoolLevel?> {
  @override
  Future<SchoolLevel?> build() => ref.read(levelStoreProvider).load();

  /// 화면에는 바로 반영하고 기기에 저장한다. 저장이 실패하면 예외를 그대로 낸다 —
  /// 이번 실행에서는 고른 학교급으로 쓰고, 화면이 실패를 알린다.
  Future<void> select(SchoolLevel level) async {
    state = AsyncData(level);
    await ref.read(levelStoreProvider).save(level);
  }
}

final selectedLevelProvider =
    AsyncNotifierProvider<SelectedLevel, SchoolLevel?>(SelectedLevel.new);
