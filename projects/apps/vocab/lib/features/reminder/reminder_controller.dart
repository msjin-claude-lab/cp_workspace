import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_info.dart';
import '../../data/counts.dart';
import '../../data/reminder_settings.dart';
import '../../data/study_decks.dart';
import '../../data/study_records.dart';
import 'reminder_notifications.dart';
import 'reminder_schedule.dart';

/// 매일 알림 설정(앱 전체)과 예약. 설정을 바꾸거나 앱을 열고 돌아올 때, 고른 단어장이 바뀔 때,
/// 오늘의 단어를 끝낼 때 [reschedule]로 다시 예약한다.
class ReminderController extends AsyncNotifier<ReminderSettings> {
  @override
  Future<ReminderSettings> build() async {
    try {
      return await ref.watch(reminderSettingsStoreProvider).load();
    } catch (_) {
      return const ReminderSettings();
    }
  }

  ReminderNotifications get _notifications =>
      ref.read(reminderNotificationsProvider);

  /// 처음 실행 때(이 기능이 생기기 전 버전에서 올라온 사용자도 업데이트 뒤 처음 한 번) 알림 권한을 묻는다.
  /// 허용하면 알림을 켜고(기본 20:00), 거절하면 끈 채로 둔다(2026-11-28 사용자 결정). 한 번만 묻는다.
  Future<void> askOnFirstLaunch() async {
    final store = ref.read(reminderSettingsStoreProvider);
    try {
      if (await store.loadAsked()) return;
    } catch (_) {
      return; // 물었는지 모르면 묻지 않는다 — 매번 묻게 되는 것을 막는다
    }
    var granted = false;
    try {
      granted = await _notifications.requestPermission();
    } catch (_) {
      // 권한 창을 띄우지 못하면 거절과 같이 꺼 둔다
    }
    try {
      await store.saveAsked();
    } catch (_) {
      // 저장하지 못하면 다음 실행에서 한 번 더 물을 수 있다
    }
    final current = await future;
    await _save(
      granted
          ? current.copyWith(
              enabled: true,
              hour: defaultReminderHour,
              minute: defaultReminderMinute,
            )
          : current.copyWith(enabled: false),
    );
  }

  /// 켜기/끄기. 켤 때 권한이 없으면 다시 묻고, 그래도 없으면 false(켜지 않는다 — 화면이 시스템 설정을 안내).
  Future<bool> setEnabled(bool on) async {
    if (on) {
      var permitted = false;
      try {
        permitted =
            await _notifications.isPermitted() ||
            await _notifications.requestPermission();
      } catch (_) {
        permitted = false;
      }
      if (!permitted) return false;
    }
    await _save((await future).copyWith(enabled: on));
    await reschedule();
    return true;
  }

  Future<void> setTime(int hour, int minute) async {
    await _save((await future).copyWith(hour: hour, minute: minute));
    await reschedule();
  }

  /// 화면에는 바로 반영하고 기기에 남긴다(저장하지 못해도 이번 실행에서는 바꾼 값을 쓴다).
  Future<void> _save(ReminderSettings settings) async {
    state = AsyncData(settings);
    try {
      await ref.read(reminderSettingsStoreProvider).save(settings);
    } catch (_) {
      // 다음 실행에서는 전 값으로 돌아간다
    }
  }

  Future<void> _pending = Future.value();

  /// 예약을 다시 한다: 지난 예약을 지우고, 켜져 있으면 지금 홈 단어장의 오늘의 단어를 끝냈는지 보고
  /// 오늘(아직 안 끝냈고 시각 전) 또는 내일부터 매일 예약한다. 잇달아 불러도 차례로 한다.
  Future<void> reschedule() =>
      _pending = _pending.then((_) => _reschedule()).catchError((_) {});

  Future<void> _reschedule() async {
    final settings = await future;
    final notifications = _notifications;
    await notifications.cancelAll();
    if (!settings.enabled) return;
    final deck = (await ref.read(deckListProvider.future)).current;
    if (deck == null) return;
    final now = ref.read(nowProvider)();
    final decks = ref.read(studyDecksProvider);
    final today = await decks.loadDailySet(deck.deckId, dayKey(now));
    var count = today?.wordIds.length;
    if (count == null || count == 0) {
      final saved = await decks.loadDailyCount(deck.deckId);
      count = isValidDailyCount(saved) ? saved! : defaultDailyCount;
    }
    await notifications.scheduleDaily(
      first: nextReminderTime(
        now,
        hour: settings.hour,
        minute: settings.minute,
        completedToday: today?.completed ?? false,
      ),
      title: appTitle,
      body: reminderBody(count),
      payload: deck.id,
    );
  }
}

final reminderControllerProvider =
    AsyncNotifierProvider<ReminderController, ReminderSettings>(
      ReminderController.new,
    );
