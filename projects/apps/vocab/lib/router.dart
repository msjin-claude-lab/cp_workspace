import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'data/cell.dart';
import 'features/about/about_screen.dart';
import 'features/home/home_screen.dart';
import 'features/progress/progress_screen.dart';
import 'features/quiz/quiz_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/study/study_screen.dart';
import 'features/wrong_notes/wrong_notes_screen.dart';

/// 화면 목록. 화면을 추가하면 여기에 경로를 더한다.
///
/// 카드 학습·시험·오답 노트·진도 주소의 `:deckId`는 이름 있는 단어장 id(`deck_2`),
/// 또는 칸 id(`elementary_easy`).
GoRouter createRouter() => GoRouter(
  routes: [
    // 단어장 홈(단어장이 없으면 시작 화면)
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    // 앱 정보(☰ 메뉴 맨 아래): 버전·오픈소스 라이선스
    GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
    // 새 단어장: 이름(창) → 학교급 → 난이도. 예: /pick?name=단어장, /pick/middle?name=단어장
    GoRoute(
      path: '/pick',
      builder: (context, state) {
        final name = state.uri.queryParameters['name'];
        if (name == null || name.trim().isEmpty) return const _NotFound();
        return LevelPickerScreen(name: name);
      },
    ),
    GoRoute(
      path: '/pick/:level',
      builder: (context, state) {
        final name = state.uri.queryParameters['name'];
        final levelName = state.pathParameters['level'];
        if (name == null || name.trim().isEmpty) return const _NotFound();
        for (final level in SchoolLevel.values) {
          if (level.name == levelName) {
            return DifficultyPickerScreen(level: level, name: name);
          }
        }
        return const Scaffold(body: Center(child: Text('없는 학교급입니다')));
      },
    ),
    // 카드 학습. 예: /study/elementary_easy, /study/deck_2
    GoRoute(
      path: '/study/:deckId',
      builder: (context, state) =>
          _withDeck(state, (deck) => StudyScreen(deck: deck)),
    ),
    // 4지선다 시험. 예: /quiz/elementary_easy
    GoRoute(
      path: '/quiz/:deckId',
      builder: (context, state) =>
          _withDeck(state, (deck) => QuizScreen(deck: deck)),
    ),
    // 오답 노트. 예: /wrong-notes/middle_medium
    GoRoute(
      path: '/wrong-notes/:deckId',
      builder: (context, state) =>
          _withDeck(state, (deck) => WrongNotesScreen(deck: deck)),
    ),
    // 진도(지금 단어장 하나). 예: /progress/deck_2
    GoRoute(
      path: '/progress/:deckId',
      builder: (context, state) =>
          _withDeck(state, (deck) => ProgressScreen(deck: deck)),
    ),
    // 설정: 그 단어장의 카드 학습 단어 수·시험 문항 수(2026-11-22 사용자 결정 — 단어장마다 따로).
    // 예: /settings/deck_2. 내장 칸은 고유 설정이 없어 찾을 수 없는 화면
    GoRoute(
      path: '/settings/:deckId',
      builder: (context, state) => _withDeck(
        state,
        (deck) => switch (deck) {
          StudyDeck() => SettingsScreen(deck: deck),
          Cell() => const _NotFound(),
        },
      ),
    ),
    // 오답 노트 → 오답 시험. 예: /review/quiz/middle_easy
    // (카드로 다시 보기는 2026-11-22 사용자 결정으로 뺐다)
    GoRoute(
      path: '/review/quiz/:deckId',
      builder: (context, state) =>
          _withDeck(state, (deck) => QuizScreen(deck: deck, review: true)),
    ),
  ],
);

/// 주소의 단어장·칸 id로 화면을 만든다. 없는 것이면 안내만 보인다.
/// 이름 있는 단어장은 이름(제목)을 읽은 뒤 만든다.
Widget _withDeck(GoRouterState state, Widget Function(Deck deck) build) {
  final id = state.pathParameters['deckId']!;
  if (StudyDeck.parseId(id) case final deckId?) {
    return StudyDeckLoader(deckId: deckId, builder: build);
  }
  if (Cell.byId(id) case final cell?) return build(cell);
  return const _NotFound();
}

/// 없는 주소. 화면에 "칸"이라는 말은 쓰지 않는다.
class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('찾을 수 없는 화면입니다')));
}

final appRouter = createRouter();
