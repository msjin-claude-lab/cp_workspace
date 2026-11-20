import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'data/cell.dart';
import 'features/home/home_screen.dart';
import 'features/study/study_screen.dart';

/// 화면 목록. 화면을 추가하면 여기에 경로를 더한다.
GoRouter createRouter() => GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        // 카드 학습. 예: /study/elementary_easy
        GoRoute(
          path: '/study/:cellId',
          builder: (context, state) {
            final cell = Cell.byId(state.pathParameters['cellId']!);
            if (cell == null) {
              return const Scaffold(body: Center(child: Text('없는 칸입니다')));
            }
            return StudyScreen(cell: cell);
          },
        ),
      ],
    );

final appRouter = createRouter();
