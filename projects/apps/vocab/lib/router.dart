import 'package:go_router/go_router.dart';

import 'features/home/home_screen.dart';

/// 화면 목록. 화면을 추가하면 여기에 경로를 더한다.
final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
  ],
);
