import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

/// 기기의 로컬 알림(인터넷 없이 기기 안에서만). 시험에서는 가짜로 바꿔 플랫폼 채널을 쓰지 않는다.
abstract interface class ReminderNotifications {
  /// 알림을 쓸 준비를 한다. 앱이 떠 있을 때 알림을 누르면 `onTap`에 알림의 payload(단어장 id)가 온다.
  Future<void> initialize(void Function(String? payload) onTap);

  /// 앱이 알림을 눌러 시작됐으면 그 payload, 아니면 null.
  Future<String?> launchPayload();

  /// 지금 알림이 허용돼 있나.
  Future<bool> isPermitted();

  /// 알림 권한을 묻는다(안드로이드 13+). 허용되면 true. 이미 거절이 굳어졌으면 묻지 않고 false가 온다.
  Future<bool> requestPermission();

  /// 이 앱의 시스템 알림 설정 화면을 연다(권한 거절이 굳어졌을 때 안내용).
  Future<void> openSettings();

  /// 예약한 알림을 모두 지운다.
  Future<void> cancelAll();

  /// `first`부터 매일 같은 시각에 알림을 되풀이한다(정확한 알람 권한 없이 몇 분 늦을 수 있는 일반 예약).
  Future<void> scheduleDaily({
    required DateTime first,
    required String title,
    required String body,
    required String payload,
  });
}

/// flutter_local_notifications 구현. 예약은 패키지가 기기에 남겨 재부팅·앱 업데이트 뒤에도 다시 건다
/// (`AndroidManifest.xml`의 ScheduledNotificationBootReceiver).
class PluginReminderNotifications implements ReminderNotifications {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _id = 1;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> initialize(void Function(String? payload) onTap) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // 권한은 처음 실행 흐름에서 따로 묻는다
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) => onTap(response.payload),
    );
  }

  @override
  Future<String?> launchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return details.notificationResponse?.payload;
  }

  @override
  Future<bool> isPermitted() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return (await _ios?.checkPermissions())?.isEnabled ?? false;
    }
    return await _android?.areNotificationsEnabled() ?? false;
  }

  @override
  Future<bool> requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await _ios?.requestPermissions(alert: true, sound: true) ?? false;
    }
    return await _android?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> openSettings() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _ios?.openAppNotificationSettings();
    } else {
      await _android?.openAppNotificationSettings();
    }
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<void> scheduleDaily({
    required DateTime first,
    required String title,
    required String body,
    required String payload,
  }) => _plugin.zonedSchedule(
    id: _id,
    // 기기 시각을 UTC 순간으로 바꿔 넘긴다(시간대 DB 없이). 되풀이는 UTC 기준 같은 시각이라
    // 서머타임이 있는 지역에서는 바뀐 뒤 한 시간 어긋날 수 있다 — 한국은 서머타임이 없다
    scheduledDate: tz.TZDateTime.from(first, tz.UTC),
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_reminder',
        '매일 알림',
        channelDescription: '오늘의 단어를 아직 다 보지 않은 날 정한 시각에 알려 줍니다',
      ),
      iOS: DarwinNotificationDetails(),
    ),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    title: title,
    body: body,
    payload: payload,
    matchDateTimeComponents: DateTimeComponents.time,
  );
}

final reminderNotificationsProvider = Provider<ReminderNotifications>(
  (ref) => PluginReminderNotifications(),
);
