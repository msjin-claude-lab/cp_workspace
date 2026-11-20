import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vocab/data/cell.dart';
import 'package:vocab/data/speaker.dart';
import 'package:vocab/data/study_records.dart';
import 'package:vocab/data/word.dart';
import 'package:vocab/data/word_repository.dart';
import 'package:vocab/features/quiz/quiz.dart';
import 'package:vocab/features/quiz/quiz_screen.dart';

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
  Future<void> recordAnswer({
    required Cell cell,
    required Word word,
    required bool known,
  }) => throw UnimplementedError('시험은 학습 기록을 쓰지 않는다');

  @override
  Future<void> recordQuizAnswer({
    required Cell cell,
    required Word word,
    required bool correct,
  }) async {
    quiz.add((word.id, correct));
    if (fail) throw StateError('db');
  }
}

void main() {
  group('buildQuiz', () {
    test('50단어에서 서로 다른 10단어를 내고, 보기 4개는 같은 칸의 서로 다른 단어이며 정답을 포함한다', () {
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

    test('단어가 10개보다 적으면 전부, 4개보다 적으면 시험을 내지 않는다', () {
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

    Future<void> pumpQuiz(WidgetTester tester, List<Word> words) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            wordRepositoryProvider.overrideWithValue(_FakeRepository(words)),
            speakerProvider.overrideWithValue(speaker),
            studyRecordsProvider.overrideWithValue(records),
            quizRandomProvider.overrideWithValue(Random(seed)),
          ],
          child: const MaterialApp(home: QuizScreen(cell: Cell.elementaryEasy)),
        ),
      );
      await tester.pumpAndSettle();
    }

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
      expect(find.text('틀린 단어 1개는 오답 노트에 담았습니다'), findsOneWidget);

      await tapShown(tester, find.text('다시 하기 (새로 섞기)'));

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

    testWidgets('칸에 50단어가 있으면 10문제를 낸다', (tester) async {
      await pumpQuiz(tester, _words(50));
      expect(find.text('1 / 10'), findsOneWidget);
    });

    testWidgets('단어가 4개보다 적으면 시험을 낼 수 없다고 알린다', (tester) async {
      await pumpQuiz(tester, _words(3));
      expect(find.text('단어가 4개 이상 있어야 시험을 볼 수 있습니다'), findsOneWidget);
    });
  });
}
