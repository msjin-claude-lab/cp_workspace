/// 다음 매일 알림 시각(기기 시각 기준). 오늘의 단어를 아직 끝내지 않았고 오늘 그 시각이 아직 오지
/// 않았으면 오늘, 아니면(끝냈거나 시각이 지났으면) 내일 그 시각(2026-11-28 사용자 결정 — 끝낸 날은
/// 보내지 않는다). 이 시각부터 매일 같은 시각에 되풀이하고, 끝내는 순간 다시 계산해 내일부터로 옮긴다.
DateTime nextReminderTime(
  DateTime now, {
  required int hour,
  required int minute,
  required bool completedToday,
}) {
  final today = DateTime(now.year, now.month, now.day, hour, minute);
  if (!completedToday && today.isAfter(now)) return today;
  // 날짜를 하나 더해 만든다 — 달·해가 바뀌어도 맞다
  return DateTime(now.year, now.month, now.day + 1, hour, minute);
}

/// 알림 문구(개수는 그 단어장의 오늘의 단어 개수).
String reminderBody(int count) => '오늘의 단어 $count개가 기다려요';
