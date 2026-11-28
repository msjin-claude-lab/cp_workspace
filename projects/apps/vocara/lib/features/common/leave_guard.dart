import 'package:material_ui/material_ui.dart';

/// 카드 학습·시험 도중에 나가려 할 때 묻는다. 나가기를 누르면 true.
/// 창 바깥을 눌러 닫으면 계속하는 것으로 본다.
/// (2026-11-22 사용자 결정(UX 점검) — ← 를 잘못 눌러 진행한 것을 잃지 않게)
Future<bool> confirmLeaveSession(BuildContext context) async {
  final leave = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('그만할까요?'),
      content: const Text('지금까지 한 기록은 저장됩니다.\n다음에는 처음부터 다시 시작합니다'),
      actions: [
        TextButton(
          key: const ValueKey('leave-continue'),
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('계속하기'),
        ),
        TextButton(
          key: const ValueKey('leave-exit'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('나가기'),
        ),
      ],
    ),
  );
  return leave ?? false;
}

/// 도중에 나가려는 것을 막고 묻는 `PopScope`. `inProgress`가 false면 그냥 나간다.
/// ← 뒤로와 시스템 뒤로 모두 여기를 지난다.
class LeaveGuard extends StatefulWidget {
  const LeaveGuard({super.key, required this.inProgress, required this.child});

  final bool inProgress;
  final Widget child;

  @override
  State<LeaveGuard> createState() => _LeaveGuardState();
}

class _LeaveGuardState extends State<LeaveGuard> {
  /// 묻는 중이거나 나가기로 해 닫히는 중. 뒤로를 연타해도 창이 겹치거나 두 번 닫지 않게 한다.
  bool _busy = false;

  /// 나가기로 했다 — 다음 그림부터 막지 않는다.
  bool _leave = false;

  Future<void> _ask() async {
    if (_busy) return;
    _busy = true;
    final navigator = Navigator.of(context);
    final leave = await confirmLeaveSession(context);
    if (!mounted) return;
    if (!leave) {
      _busy = false;
      return;
    }
    setState(() => _leave = true);
    // canPop이 true로 다시 그려진 뒤에 닫는다
    WidgetsBinding.instance.addPostFrameCallback((_) => navigator.pop());
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _leave || !widget.inProgress,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _ask();
      },
      child: widget.child,
    );
  }
}
