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
/// 카드 학습·시험·오답 노트 주소의 `:deckId`는 칸 id(`elementary_easy`) 또는 내 단어장 id(`book_3`).
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
    // 진도. 지금 고른 칸을 강조하려면 ?cell=middle_medium
    GoRoute(
      path: '/progress',
      builder: (context, state) => ProgressScreen(
        current: Cell.byId(state.uri.queryParameters['cell'] ?? ''),
      ),
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
    // 내 단어장 목록(☰ 메뉴 → 내 단어장)과 단어장 하나. 예: /books/3
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

/// 주소의 칸·내 단어장 id로 화면을 만든다. 없는 칸이면 안내만 보인다.
/// 내 단어장은 이름(제목)을 DB에서 읽은 뒤 만든다.
Widget _withDeck(GoRouterState state, Widget Function(Deck deck) build) {
  final id = state.pathParameters['deckId']!;
  if (Cell.byId(id) case final cell?) return build(cell);
  if (BookDeck.parseId(id) case final bookId?) {
    return BookDeckLoader(bookId: bookId, builder: build);
  }
  // 화면에 "칸"이라는 말은 쓰지 않는다
  return const Scaffold(body: Center(child: Text('찾을 수 없는 화면입니다')));
}

final appRouter = createRouter();
