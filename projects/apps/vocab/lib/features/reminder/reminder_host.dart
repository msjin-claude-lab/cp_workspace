import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/cell.dart';
import '../../data/study_decks.dart';
import '../today/today_words.dart';
import 'reminder_controller.dart';
import 'reminder_notifications.dart';

/// 앱 전체를 감싸 매일 알림을 돌본다(2026-11-28 사용자 결정):
/// - 시작할 때 알림을 준비하고, 알림을 눌러 시작됐으면 오늘의 단어 화면을 연다
/// - 처음 실행 때 한 번 알림 권한을 묻고 예약한다
/// - 앱이 떠 있을 때 알림을 누르면 오늘의 단어 화면을 연다
/// - 앱으로 돌아올 때(날짜가 바뀌었을 수 있다)와 고른 단어장이 바뀔 때 다시 예약한다
class ReminderHost extends ConsumerStatefulWidget {
  const ReminderHost({super.key, required this.router, required this.child});

  final GoRouter router;
  final Widget child;

  @override
  ConsumerState<ReminderHost> createState() => _ReminderHostState();
}

class _ReminderHostState extends ConsumerState<ReminderHost>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 첫 화면을 그린 뒤 시작한다(화면 이동은 라우터가 붙은 뒤에)
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _start() async {
    final notifications = ref.read(reminderNotificationsProvider);
    final controller = ref.read(reminderControllerProvider.notifier);
    try {
      await notifications.initialize(_openToday);
      _openToday(await notifications.launchPayload());
    } catch (_) {
      // 알림을 쓸 수 없어도 앱은 그대로 쓴다
    }
    await controller.askOnFirstLaunch();
    await controller.reschedule();
  }

  /// 알림의 payload(`deck_2`)로 그 단어장의 오늘의 단어 화면을 연다.
  void _openToday(String? payload) {
    if (payload == null || StudyDeck.parseId(payload) == null || !mounted) {
      return;
    }
    final path = '/today/$payload';
    // 이미 그 화면에 있으면 같은 화면을 하나 더 쌓지 않는다
    if (widget.router.routerDelegate.currentConfiguration.uri.path == path) {
      return;
    }
    widget.router.push(path);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // 자정을 넘겼으면 홈의 오늘의 단어를 새 날짜로 다시 고른다
    ref.invalidate(todayWordsProvider);
    ref.read(reminderControllerProvider.notifier).reschedule();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(deckListProvider.select((list) => list.value?.current?.deckId), (
      previous,
      next,
    ) {
      if (previous != next) {
        ref.read(reminderControllerProvider.notifier).reschedule();
      }
    });
    return widget.child;
  }
}
