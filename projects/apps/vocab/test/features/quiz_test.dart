import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vocab/data/app_settings.dart';
import 'package:vocab/data/cell.dart';
import 'package:vocab/data/speaker.dart';
import 'package:vocab/data/study_records.dart';
import 'package:vocab/data/word.dart';
import 'package:vocab/data/word_repository.dart';
import 'package:vocab/features/quiz/quiz.dart';
import 'package:vocab/features/quiz/quiz_screen.dart';

import '../fakes.dart' show FakeAppSettingsStore;

List<Word> _words(int n) => [
  for (var i = 0; i < n; i++)
    Word(
      id: 'ee-${i.toString().padLeft(3, '0')}',
      word: 'word$i',
      meaning: '뜻$i',
      example: 'example $i',
      exampleMeaning: '예문 해석 $i',
    ),
];

class _FakeRepository implements WordRepository {
  _FakeRepository(this.words);

  final List<Word> words;

  @override
  Future<List<Word>> wordsOf(Cell cell) async => words;
}

class _FakeSpeaker implements Speaker {
  final List<String> spoken = [];

  @override
  Future<void> speak(String text) async => spoken.add(text);
}

class _FakeRecords implements StudyRecords {
  final List<(String, bool)> quiz = [];
  bool fail = false;

  @override
  Future<void> recordCardViewed({required Deck deck, required Word word}) =>
      throw UnimplementedError('시험은 학습 기록을 쓰지 않는다');

  @override
  Future<void> recordQuizAnswer({
    required Deck deck,
    required Word word,
    required bool correct,
  }) async {
    quiz.add((word.id, correct));
    if (fail) throw StateError('db');
  }

  /// 가짜 오답 노트. 오답 시험 시험이 채운다.
  final List<WrongNote> notes = [];
  final List<String> removed = [];

  @override
  Future<List<WrongNote>> wrongNotes(SchoolLevel level) async => [
    for (final n in notes)
      if (n.deck case Cell(level: final l) when l == level) n,
  ];

  @override
  Future<List<WrongNote>> deckWrongNotes(Deck deck) async => [
    for (final n in notes)
      if (n.deck.id == deck.id) n,
  ];

  @override
  Future<void> removeWrongNote(Deck deck, String wordId) async {
    removed.add(wordId);
    notes.removeWhere((n) => n.deck.id == deck.id && n.wordId == wordId);
  }

  @override
  Future<void> restoreWrongNote(WrongNote note) async => notes.add(note);

  @override
  Future<Progress> progress(Deck deck) async => const Progress();
}

void main() {
  group('buildQuiz', () {
    test('50단어에서 서로 다른 20단어를 내고, 보기 4개는 같은 칸의 서로 다른 단어이며 정답을 포함한다', () {
      final words = _words(50);
      final quiz = buildQuiz(words, Random(1));

      expect(quiz, hasLength(quizLength));
      expect(quiz.map((q) => q.word.id).toSet(), hasLength(quizLength));
      for (final q in quiz) {
        expect(q.options, hasLength(quizOptionCount));
        expect(q.options.toSet(), hasLength(quizOptionCount));
        expect(q.options.every(words.contains), isTrue);
        expect(q.options[q.answerIndex], same(q.word));
      }
    });

    test('부를 때마다 새로 섞는다', () {
      final words = _words(50);
      final random = Random(1);
      final first = buildQuiz(words, random).map((q) => q.word.id).toList();
      final second = buildQuiz(words, random).map((q) => q.word.id).toList();
      expect(second, isNot(first));
    });

    test('방향은 영→뜻·뜻→영이 섞여 나오고, 보기 글자는 방향을 따른다', () {
      final quiz = buildQuiz(_words(50), Random(3), length: 50);
      final directions = quiz.map((q) => q.direction).toSet();
      expect(directions, QuizDirection.values.toSet());

      final toMeaning = quiz.firstWhere(
        (q) => q.direction == QuizDirection.wordToMeaning,
      );
      expect(toMeaning.prompt, toMeaning.word.word);
      expect(toMeaning.optionText(toMeaning.word), toMeaning.word.meaning);
      final toWord = quiz.firstWhere(
        (q) => q.direction == QuizDirection.meaningToWord,
      );
      expect(toWord.prompt, toWord.word.meaning);
      expect(toWord.optionText(toWord.word), toWord.word.word);
    });

    test('뜻이나 영단어가 같은 단어가 있어도 보기 글자는 서로 겹치지 않는다(내 단어장)', () {
      Word w(String id, String word, String meaning) => Word(
        id: id,
        word: word,
        meaning: meaning,
        example: '',
        exampleMeaning: '',
      );
      final words = [
        w('bw-1', 'big', '큰'),
        w('bw-2', 'large', '큰'), // 뜻이 같다
        w('bw-3', 'cat', '고양이'),
        w('bw-4', 'cat', '고양잇과 동물'), // 영단어가 같다
        w('bw-5', 'dog', '개'),
        w('bw-6', 'bird', '새'),
      ];
      // 씨앗을 바꿔 가며 여러 번 — 한 번이라도 같은 글자의 보기가 둘이면 안 된다
      for (var seed = 0; seed < 200; seed++) {
        for (final q in buildQuiz(words, Random(seed))) {
          final texts = q.options.map(q.optionText).toList();
          expect(texts.toSet(), hasLength(quizOptionCount), reason: '$texts');
          expect(q.options[q.answerIndex], same(q.word));
        }
      }
    });

    test('서로 다른 영단어·뜻이 4개가 안 되면 시험을 내지 않고 까닭을 알려 준다', () {
      Word w(String word, String meaning) => Word(
        id: word + meaning,
        word: word,
        meaning: meaning,
        example: '',
        exampleMeaning: '',
      );
      expect(quizBlockReason(_words(3)), contains('4개 이상'));
      expect(quizBlockReason(_words(4)), isNull);
      // 4단어지만 뜻이 3가지뿐
      final sameMeaning = [w('a', '큰'), w('b', '큰'), w('c', '개'), w('d', '새')];
      expect(quizBlockReason(sameMeaning), contains('서로 다른'));
      expect(buildQuiz(sameMeaning, Random(1)), isEmpty);
      // 4단어지만 영단어가 3가지뿐
      final sameWord = [w('a', '1'), w('a', '2'), w('c', '3'), w('d', '4')];
      expect(quizBlockReason(sameWord), contains('서로 다른'));
    });

    test('단어가 20개보다 적으면 전부, 4개보다 적으면 시험을 내지 않는다', () {
      expect(buildQuiz(_words(19), Random(1)), hasLength(19));
      expect(buildQuiz(_words(6), Random(1)), hasLength(6));
      expect(buildQuiz(_words(4), Random(1)), hasLength(4));
      expect(buildQuiz(_words(3), Random(1)), isEmpty);
    });
  });

  group('QuizScreen', () {
    late _FakeSpeaker speaker;
    late _FakeRecords records;
    const seed = 7;

    setUp(() {
      speaker = _FakeSpeaker();
      records = _FakeRecords();
    });

    /// 화면이 쓸 것과 같은 씨앗으로 만든 문제 — 정답 위치를 미리 안다.
    List<QuizQuestion> expected(List<Word> words) =>
        buildQuiz(words, Random(seed));

    Future<void> pumpQuiz(
      WidgetTester tester,
      List<Word> words, {
      bool review = false,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSettingsStoreProvider.overrideWithValue(FakeAppSettingsStore()),
            wordRepositoryProvider.overrideWithValue(_FakeRepository(words)),
            speakerProvider.overrideWithValue(speaker),
            studyRecordsProvider.overrideWithValue(records),
            quizRandomProvider.overrideWithValue(Random(seed)),
          ],
          child: MaterialApp(
            home: QuizScreen(deck: Cell.elementaryEasy, review: review),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    WrongNote note(String id) => WrongNote(
      wordId: id,
      deck: Cell.elementaryEasy,
      missCount: 1,
      lastMissedAt: 0,
    );

    Finder option(int i) => find.byKey(ValueKey('quiz-option-$i'));

    /// 시험 화면은 스크롤된다 — 시험용 화면(800×600)에서 아래 버튼이 가려지지 않게 보이도록 옮긴 뒤 누른다.
    Future<void> tapShown(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    testWidgets('맞히면 정답 표시와 예문·해석이 보이고 맞힘으로 기록된다', (tester) async {
      final words = _words(4);
      final q = expected(words).first;
      await pumpQuiz(tester, words);

      expect(find.text('1 / 4'), findsOneWidget);
      expect(find.text(q.prompt), findsOneWidget);

      await tapShown(tester, option(q.answerIndex));

      expect(find.text('정답입니다'), findsOneWidget);
      expect(find.text(q.word.example), findsOneWidget);
      expect(find.text(q.word.exampleMeaning), findsOneWidget);
      expect(records.quiz, [(q.word.id, true)]);
    });

    testWidgets('틀리면 틀림 표시, 오답으로 기록되고 다시 눌러도 한 번만 기록된다', (tester) async {
      final words = _words(4);
      final q = expected(words).first;
      final wrong = (q.answerIndex + 1) % quizOptionCount;
      await pumpQuiz(tester, words);

      await tapShown(tester, option(wrong));
      await tester.ensureVisible(option(q.answerIndex));
      await tester.pumpAndSettle();
      await tester.tap(
        option(q.answerIndex),
        warnIfMissed: false,
      ); // 이미 답함 — 막혀 있어야 한다
      await tester.pumpAndSettle();

      expect(find.text('틀렸습니다'), findsOneWidget);
      expect(records.quiz, [(q.word.id, false)]);
    });

    testWidgets('영→뜻 문제만 자동으로 발음한다(뜻→영은 답을 알려 주므로 읽지 않음)', (tester) async {
      final words = _words(4);
      final quiz = expected(words);
      await pumpQuiz(tester, words);

      for (var i = 0; i < quiz.length; i++) {
        await tapShown(tester, option(quiz[i].answerIndex));
        await tapShown(tester, find.byKey(const ValueKey('quiz-next')));
      }

      expect(speaker.spoken, [
        for (final q in quiz)
          if (q.direction == QuizDirection.wordToMeaning) q.word.word,
      ]);
    });

    testWidgets('끝나면 맞힌 수를 보여 주고, 다시 하기는 새로 섞는다', (tester) async {
      final words = _words(4);
      final quiz = expected(words);
      await pumpQuiz(tester, words);

      for (var i = 0; i < quiz.length; i++) {
        // 첫 문제만 틀린다
        final pick = i == 0
            ? (quiz[i].answerIndex + 1) % quizOptionCount
            : quiz[i].answerIndex;
        await tapShown(tester, option(pick));
        await tapShown(tester, find.byKey(const ValueKey('quiz-next')));
      }

      expect(find.text('4문제 중 3문제 맞혔습니다'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('틀린 단어는 오답 노트에 있습니다'), findsOneWidget);
      // 이번에 틀린 단어(첫 문제)가 영단어 — 뜻으로 보인다
      expect(find.text('이번에 틀린 단어'), findsOneWidget);
      expect(
        find.text('${quiz[0].word.word} — ${quiz[0].word.meaning}'),
        findsOneWidget,
      );
      expect(find.text('다시 하기 (새로 섞기)'), findsNothing);
      expect(find.text('오답 노트 보기'), findsOneWidget);
      expect(find.text('홈으로'), findsOneWidget);

      await tapShown(tester, find.byKey(const ValueKey('quiz-again')));

      // 같은 난수를 이어 쓰므로 두 번째 회차는 첫 회차와 다르게 섞인다
      final random = Random(seed);
      buildQuiz(words, random);
      final second = buildQuiz(words, random);
      expect(find.text('1 / 4'), findsOneWidget);
      expect(find.text(second.first.prompt), findsOneWidget);
    });

    testWidgets('저장에 실패하면 알리고 계속 진행한다', (tester) async {
      records.fail = true;
      final words = _words(4);
      final q = expected(words).first;
      await pumpQuiz(tester, words);

      await tapShown(tester, option(q.answerIndex));

      expect(find.byKey(const ValueKey('quiz-save-error')), findsOneWidget);
      expect(find.byKey(const ValueKey('quiz-next')), findsOneWidget);
    });

    testWidgets('오답 시험은 노트 단어만 묻고 보기는 칸 전체에서 고르며, 맞힌 단어만 노트에서 뺀다', (
      tester,
    ) async {
      final words = _words(6);
      records.notes.addAll([note('ee-001'), note('ee-004')]);
      // 화면과 같은 입력(노트 단어를 파일 순서로, 보기 후보는 칸 전체)으로 정답 위치를 미리 안다
      final quiz = buildQuiz([words[1], words[4]], Random(seed), pool: words);
      await pumpQuiz(tester, words, review: true);

      expect(find.text('초등 [난이도 : 쉬움] - 오답 시험'), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);
      for (final q in quiz) {
        expect(q.options, hasLength(quizOptionCount)); // 노트는 2단어여도 보기는 4개
      }

      // 첫 문제는 맞히고, 둘째 문제는 틀린다
      await tapShown(tester, option(quiz[0].answerIndex));
      await tapShown(tester, find.byKey(const ValueKey('quiz-next')));
      await tapShown(tester, option((quiz[1].answerIndex + 1) % 4));
      await tapShown(tester, find.byKey(const ValueKey('quiz-next')));

      expect(records.removed, [quiz[0].word.id]);
      expect(find.text('맞힌 1단어는 오답 노트에서 뺐습니다'), findsOneWidget);
      expect(find.text('틀린 1단어는 오답 노트에 남았습니다'), findsOneWidget);

      // 다시 하기는 남은 오답만
      await tapShown(tester, find.text('남은 오답 다시 하기'));
      expect(find.text('1 / 1'), findsOneWidget); // 맞혀서 뺀 단어는 다시 묻지 않는다
    });

    testWidgets('일반 시험에서 맞혀도 오답 노트에서 빼지 않는다', (tester) async {
      final words = _words(4);
      final q = expected(words).first;
      records.notes.add(note(q.word.id));
      await pumpQuiz(tester, words);

      await tapShown(tester, option(q.answerIndex));

      expect(records.removed, isEmpty);
    });

    /// 홈 → 시험 순으로 쌓은 라우터. 오답 노트 주소는 표시만 하는 가짜 화면.
    Future<GoRouter> pumpQuizRoute(
      WidgetTester tester,
      List<Word> words, {
      bool review = false,
    }) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('홈 화면')),
          ),
          GoRoute(
            path: '/quiz',
            builder: (_, _) =>
                QuizScreen(deck: Cell.elementaryEasy, review: review),
          ),
          GoRoute(
            path: '/wrong-notes/:id',
            builder: (_, state) => Scaffold(
              appBar: AppBar(),
              body: Text('노트 ${state.pathParameters['id']}'),
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSettingsStoreProvider.overrideWithValue(FakeAppSettingsStore()),
            wordRepositoryProvider.overrideWithValue(_FakeRepository(words)),
            speakerProvider.overrideWithValue(speaker),
            studyRecordsProvider.overrideWithValue(records),
            quizRandomProvider.overrideWithValue(Random(seed)),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      router.push('/quiz');
      await tester.pumpAndSettle();
      return router;
    }

    /// 문제를 모두 푼다. `wrongAt`에 든 번호는 틀린다.
    Future<void> solveAll(
      WidgetTester tester,
      List<QuizQuestion> quiz, {
      Set<int> wrongAt = const {},
    }) async {
      for (var i = 0; i < quiz.length; i++) {
        final pick = wrongAt.contains(i)
            ? (quiz[i].answerIndex + 1) % quizOptionCount
            : quiz[i].answerIndex;
        await tapShown(tester, option(pick));
        await tapShown(tester, find.byKey(const ValueKey('quiz-next')));
      }
    }

    testWidgets('결과에서 오답 노트 보기는 시험 화면을 노트로 바꿔 열어, 뒤로 가면 홈이다', (tester) async {
      final words = _words(4);
      final quiz = expected(words);
      final router = await pumpQuizRoute(tester, words);
      await solveAll(tester, quiz, wrongAt: {0});

      await tapShown(tester, find.byKey(const ValueKey('quiz-to-notes')));
      expect(find.text('노트 ${Cell.elementaryEasy.id}'), findsOneWidget);
      expect(find.byType(QuizScreen), findsNothing);

      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('홈 화면'), findsOneWidget);
    });

    testWidgets('결과에서 홈으로는 홈에 간다', (tester) async {
      final words = _words(4);
      await pumpQuizRoute(tester, words);
      await solveAll(tester, expected(words), wrongAt: {1});

      await tapShown(tester, find.byKey(const ValueKey('quiz-home')));
      expect(find.text('홈 화면'), findsOneWidget);
    });

    testWidgets('다 맞히면 오답 노트 보기와 틀린 단어 목록이 없고, 오답 시험 결과는 홈으로·노트 보기가 없다', (
      tester,
    ) async {
      final words = _words(4);
      final quiz = expected(words);
      await pumpQuiz(tester, words);
      await solveAll(tester, quiz);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('오답 노트 보기'), findsNothing);
      expect(find.text('이번에 틀린 단어'), findsNothing);
      expect(find.text('틀린 단어는 오답 노트에 있습니다'), findsNothing);
    });

    testWidgets('오답 시험 결과에는 홈으로·오답 노트 보기가 없고 남은 오답 다시 하기·오답 노트로가 있다', (
      tester,
    ) async {
      final words = _words(4);
      records.notes.add(note('ee-001'));
      final reviewQuiz = buildQuiz([words[0]], Random(seed), pool: words);
      await pumpQuiz(tester, words, review: true);
      await solveAll(tester, reviewQuiz, wrongAt: {0});
      expect(find.text('남은 오답 다시 하기'), findsOneWidget);
      expect(find.text('오답 노트로'), findsOneWidget);
      expect(find.text('오답 노트 보기'), findsNothing);
      expect(find.text('홈으로'), findsNothing);
      expect(find.text('이번에 틀린 단어'), findsOneWidget);
    });

    testWidgets('첫 문제에서 아직 답하지 않았으면 ← 뒤로는 묻지 않고 나간다', (tester) async {
      final words = _words(4);
      await pumpQuizRoute(tester, words);

      // 첫 문제에서 아직 답하지 않았다 — 묻지 않고 나간다
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('그만할까요?'), findsNothing);
      expect(find.text('홈 화면'), findsOneWidget);
    });

    testWidgets('답한 뒤 뒤로를 누르면 묻고, 계속하기는 남고 나가기는 나간다', (tester) async {
      final words = _words(4);
      final quiz = expected(words);
      await pumpQuizRoute(tester, words);
      await tapShown(tester, option(quiz[0].answerIndex));

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('그만할까요?'), findsOneWidget);
      await tapShown(tester, find.byKey(const ValueKey('leave-continue')));
      expect(find.byType(QuizScreen), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('그만할까요?'), findsOneWidget);
      await tapShown(tester, find.byKey(const ValueKey('leave-exit')));
      expect(find.byType(QuizScreen), findsNothing);
      expect(find.text('홈 화면'), findsOneWidget);
      expect(records.quiz, [(quiz[0].word.id, true)]); // 푼 기록은 남는다
    });

    testWidgets('결과 화면에서는 뒤로를 눌러도 묻지 않는다', (tester) async {
      final words = _words(4);
      await pumpQuizRoute(tester, words);
      await solveAll(tester, expected(words));

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('그만할까요?'), findsNothing);
      expect(find.text('홈 화면'), findsOneWidget);
    });

    testWidgets('칸에 50단어가 있으면 20문제를 낸다', (tester) async {
      await pumpQuiz(tester, _words(50));
      expect(find.text('1 / 20'), findsOneWidget);
    });

    testWidgets('단어가 4개보다 적으면 시험을 낼 수 없다고 알린다', (tester) async {
      await pumpQuiz(tester, _words(3));
      expect(find.text('단어가 4개 이상 있어야 시험을 볼 수 있습니다'), findsOneWidget);
    });
  });
}
