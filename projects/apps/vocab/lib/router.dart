import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'data/cell.dart';
import 'features/home/home_screen.dart';
import 'features/my_words/word_book_screen.dart';
import 'features/my_words/word_books_screen.dart';
import 'features/progress/progress_screen.dart';
import 'features/quiz/quiz_screen.dart';
import 'features/study/study_screen.dart';
import 'features/wrong_notes/wrong_notes_screen.dart';

/// 화면 목록. 화면을 추가하면 여기에 경로를 더한다.
///
/// 카드 학습·시험·오답 노트·진도 주소의 `:deckId`는 이름 있는 단어장 id(`deck_2`),
/// 칸 id(`elementary_easy`) 또는 내 단어장 id(`book_3`).
GoRouter createRouter() => GoRouter(
  routes: [
    // 단어장 홈(단어장이 없으면 시작 화면)
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
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
    // 카드 학습. 예: /study/elementary_easy, /study/book_3
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
    // 오답 노트 → 카드로 다시 보기 / 오답 시험. 예: /review/quiz/middle_easy
    GoRoute(
      path: '/review/study/:deckId',
      builder: (context, state) =>
          _withDeck(state, (deck) => StudyScreen(deck: deck, review: true)),
    ),
    GoRoute(
      path: '/review/quiz/:deckId',
      builder: (context, state) =>
          _withDeck(state, (deck) => QuizScreen(deck: deck, review: true)),
    ),
    // 직접 단어를 넣는 내 단어장 목록과 단어장 하나. 예: /books/3
    // (2026-11-22 사용자 결정으로 ☰ 메뉴에서 뺐다 — 지금은 화면에서 들어가는 길이 없다)
    GoRoute(
      path: '/books',
      builder: (context, state) => const WordBooksScreen(),
    ),
    GoRoute(
      path: '/books/:bookId',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['bookId']!);
        if (id == null) return const MissingBookScreen();
        return WordBookScreen(bookId: id);
      },
    ),
  ],
);

/// 주소의 단어장·칸·내 단어장 id로 화면을 만든다. 없는 것이면 안내만 보인다.
/// 이름 있는 단어장·내 단어장은 이름(제목)을 읽은 뒤 만든다.
Widget _withDeck(GoRouterState state, Widget Function(Deck deck) build) {
  final id = state.pathParameters['deckId']!;
  if (StudyDeck.parseId(id) case final deckId?) {
    return StudyDeckLoader(deckId: deckId, builder: build);
  }
  if (Cell.byId(id) case final cell?) return build(cell);
  if (BookDeck.parseId(id) case final bookId?) {
    return BookDeckLoader(bookId: bookId, builder: build);
  }
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
