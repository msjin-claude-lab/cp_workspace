import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 매일 알림의 기본 시각(2026-11-28 사용자 결정 — 저녁 8시: 학교·저녁 뒤, 초등생에게도 늦지 않은 시각).
const int defaultReminderHour = 20;
const int defaultReminderMinute = 0;

/// 매일 알림 설정(앱 전체에 하나 — 2026-11-28 사용자 결정). 기준 단어장은 그때 홈에서 고른 단어장.
class ReminderSettings {
  const ReminderSettings({
    this.enabled = false,
    this.hour = defaultReminderHour,
    this.minute = defaultReminderMinute,
  });

  final bool enabled;
  final int hour;
  final int minute;

  ReminderSettings copyWith({bool? enabled, int? hour, int? minute}) =>
      ReminderSettings(
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
      );

  @override
  bool operator ==(Object other) =>
      other is ReminderSettings &&
      other.enabled == enabled &&
      other.hour == hour &&
      other.minute == minute;

  @override
  int get hashCode => Object.hash(enabled, hour, minute);
}

/// 매일 알림 설정과 "처음 실행 때 알림 권한을 물었다" 표시를 기기에 남긴다. 시험에서는 가짜로 바꾼다.
abstract interface class ReminderSettingsStore {
  Future<ReminderSettings> load();

  Future<void> save(ReminderSettings settings);

  /// 알림 권한을 한 번 물었나(새 설치·이 기능이 생기기 전 버전에서 올라온 사용자 모두 처음 한 번만 묻는다).
  Future<bool> loadAsked();

  Future<void> saveAsked();
}

/// shared_preferences 구현(`cell_store.dart`와 같은 방식).
class PrefsReminderSettingsStore implements ReminderSettingsStore {
  static const _enabledKey = 'reminder_enabled';
  static const _hourKey = 'reminder_hour';
  static const _minuteKey = 'reminder_minute';
  static const _askedKey = 'reminder_permission_asked';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  @override
  Future<ReminderSettings> load() async {
    final hour = await _prefs.getInt(_hourKey);
    final minute = await _prefs.getInt(_minuteKey);
    return ReminderSettings(
      enabled: await _prefs.getBool(_enabledKey) ?? false,
      hour: hour != null && hour >= 0 && hour < 24 ? hour : defaultReminderHour,
      minute: minute != null && minute >= 0 && minute < 60
          ? minute
          : defaultReminderMinute,
    );
  }

  @override
  Future<void> save(ReminderSettings settings) async {
    await _prefs.setBool(_enabledKey, settings.enabled);
    await _prefs.setInt(_hourKey, settings.hour);
    await _prefs.setInt(_minuteKey, settings.minute);
  }

  @override
  Future<bool> loadAsked() async => await _prefs.getBool(_askedKey) ?? false;

  @override
  Future<void> saveAsked() => _prefs.setBool(_askedKey, true);
}

final reminderSettingsStoreProvider = Provider<ReminderSettingsStore>(
  (ref) => PrefsReminderSettingsStore(),
);
