import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// 화면 위쪽 오른편의 ⌂ 홈 버튼: 고른 칸의 홈으로 한 번에 돌아간다(2026-11-20 사용자 결정).
/// ← 뒤로는 AppBar가 알아서 붙인다.
class HomeButton extends StatelessWidget {
  const HomeButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    key: const ValueKey('go-home'),
    tooltip: '홈',
    icon: const Icon(Icons.home_outlined),
    onPressed: () => context.go('/'),
  );
}
