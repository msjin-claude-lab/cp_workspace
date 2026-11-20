import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'data/cell.dart';
import 'features/home/home_screen.dart';
import 'features/progress/progress_screen.dart';
import 'features/quiz/quiz_screen.dart';
import 'features/study/study_screen.dart';
import 'features/wrong_notes/wrong_notes_screen.dart';

/// 화면 목록. 화면을 추가하면 여기에 경로를 더한다.
GoRouter createRouter() => GoRouter(
  routes: [
    // 칸 홈(처음 실행이면 학교급 고르기)
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    // 칸 바꾸기: 학교급 → 난이도. 예: /pick, /pick/middle
    GoRoute(
      path: '/pick',
      builder: (context, state) => const LevelPickerScreen(),
    ),
    GoRoute(
      path: '/pick/:level',
      builder: (context, state) {
        final name = state.pathParameters['level'];
        for (final level in SchoolLevel.values) {
          if (level.name == name) return DifficultyPickerScreen(level: level);
        }
        return const Scaffold(body: Center(child: Text('없는 학교급입니다')));
      },
    ),
    // 카드 학습. 예: /study/elementary_easy
    GoRoute(
      path: '/study/:cellId',
      builder: (context, state) =>
          _withCell(state, (cell) => StudyScreen(cell: cell)),
    ),
    // 4지선다 시험. 예: /quiz/elementary_easy
    GoRoute(
      path: '/quiz/:cellId',
      builder: (context, state) =>
          _withCell(state, (cell) => QuizScreen(cell: cell)),
    ),
    // 오답 노트. 예: /wrong-notes/middle_medium
    GoRoute(
      path: '/wrong-notes/:cellId',
      builder: (context, state) =>
          _withCell(state, (cell) => WrongNotesScreen(cell: cell)),
    ),
    // 진도. 지금 고른 칸을 강조하려면 ?cell=middle_medium
    GoRoute(
      path: '/progress',
      builder: (context, state) => ProgressScreen(
        current: Cell.byId(state.uri.queryParameters['cell'] ?? ''),
      ),
    ),
    // 오답 노트 → 카드로 다시 보기 / 오답 시험. 예: /review/quiz/middle_easy
    GoRoute(
      path: '/review/study/:cellId',
      builder: (context, state) =>
          _withCell(state, (cell) => StudyScreen(cell: cell, review: true)),
    ),
    GoRoute(
      path: '/review/quiz/:cellId',
      builder: (context, state) =>
          _withCell(state, (cell) => QuizScreen(cell: cell, review: true)),
    ),
  ],
);

/// 주소의 칸 id로 화면을 만든다. 없는 칸이면 안내만 보인다.
Widget _withCell(GoRouterState state, Widget Function(Cell cell) build) {
  final cell = Cell.byId(state.pathParameters['cellId']!);
  if (cell == null) {
    return const Scaffold(body: Center(child: Text('없는 칸입니다')));
  }
  return build(cell);
}

final appRouter = createRouter();
