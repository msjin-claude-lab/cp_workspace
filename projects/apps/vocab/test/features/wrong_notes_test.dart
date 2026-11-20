import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vocab/data/cell.dart';
import 'package:vocab/data/cell_store.dart';
import 'package:vocab/data/speaker.dart';
import 'package:vocab/data/study_records.dart';
import 'package:vocab/data/word_repository.dart';
import 'package:vocab/features/quiz/quiz.dart';
import 'package:vocab/features/quiz/quiz_screen.dart';
import 'package:vocab/features/study/study_screen.dart';
import 'package:vocab/features/wrong_notes/wrong_notes_screen.dart';
import 'package:vocab/router.dart';

import '../fakes.dart';

void main() {
  const seed = 11;
  final easy = [
    fakeWord('ee-001', 'apple', '사과'),
    fakeWord('ee-002', 'book', '책'),
    fakeWord('ee-003', 'cup', '컵'),
    fakeWord('ee-004', 'desk', '책상'),
  ];
  final words = {
    Cell.elementaryEasy: easy,
    Cell.elementaryHard: [fakeWord('eh-001', 'castle', '성')],
  };

  late FakeRecords records;

  setUp(() => records = FakeRecords());

  /// 칸 홈(초등 · 하)에서 오답 노트로 들어간다.
  Future<void> openWrongNotes(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wordRepositoryProvider.overrideWithValue(FakeRepository(words)),
          cellStoreProvider.overrideWithValue(
            FakeCellStore(Cell.elementaryEasy),
          ),
          speakerProvider.overrideWithValue(FakeSpeaker()),
          studyRecordsProvider.overrideWithValue(records),
          quizRandomProvider.overrideWithValue(Random(seed)),
        ],
        child: MaterialApp.router(routerConfig: createRouter()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home-wrong')));
    await tester.pumpAndSettle();
  }

  Future<void> tapShown(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('오답 노트는 그 칸의 오답만, 최근에 틀린 것부터 틀린 횟수와 함께 보여 준다', (tester) async {
    records.notes.addAll([
      fakeNote('ee-001', Cell.elementaryEasy, miss: 2, at: 1),
      fakeNote('ee-003', Cell.elementaryEasy, at: 5),
      fakeNote('eh-001', Cell.elementaryHard, at: 9), // 다른 칸 — 안 보인다
    ]);
    await openWrongNotes(tester);

    expect(find.byType(WrongNotesScreen), findsOneWidget);
    expect(find.text('초등 · 하 오답 노트'), findsOneWidget);
    expect(find.text('2단어'), findsOneWidget);
    expect(find.text('castle'), findsNothing);
    expect(find.text('틀림 2'), findsOneWidget);
    // 최근에 틀린 cup(5)이 apple(1)보다 위
    expect(
      tester.getTopLeft(find.text('cup')).dy,
      lessThan(tester.getTopLeft(find.text('apple')).dy),
    );
  });

  testWidgets('지우기를 누르면 오답 노트에서 빠지고, 칸 홈의 오답 수도 바뀐다', (tester) async {
    records.notes.addAll([
      fakeNote('ee-001', Cell.elementaryEasy),
      fakeNote('ee-002', Cell.elementaryEasy),
    ]);
    await openWrongNotes(tester);

    await tester.tap(find.byKey(const ValueKey('wrong-delete-ee-001')));
    await tester.pumpAndSettle();

    expect(records.removed, ['ee-001']);
    expect(find.text('apple'), findsNothing);
    expect(find.text('1단어'), findsOneWidget);
    expect(find.text('apple — 오답 노트에서 지웠습니다'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('go-home')));
    await tester.pumpAndSettle();
    expect(find.text('오답 노트 · 1단어'), findsOneWidget);
  });

  testWidgets('오답 시험에서 맞히면 돌아온 오답 노트에서 그 단어가 사라진다', (tester) async {
    records.notes.add(fakeNote('ee-002', Cell.elementaryEasy));
    // 화면과 같은 입력으로 만든 문제 — 정답 위치를 미리 안다
    final q = buildQuiz([easy[1]], Random(seed), pool: easy).single;
    await openWrongNotes(tester);

    await tester.tap(find.byKey(const ValueKey('wrong-quiz')));
    await tester.pumpAndSettle();
    expect(find.byType(QuizScreen), findsOneWidget);
    expect(find.text('1 / 1'), findsOneWidget);

    await tapShown(
      tester,
      find.byKey(ValueKey('quiz-option-${q.answerIndex}')),
    );
    await tapShown(tester, find.byKey(const ValueKey('quiz-next')));
    await tapShown(tester, find.text('오답 노트로'));

    expect(find.byType(WrongNotesScreen), findsOneWidget);
    expect(records.removed, ['ee-002']);
    expect(find.byKey(const ValueKey('wrong-empty')), findsOneWidget);
  });

  testWidgets('카드로 다시 보기는 그 칸의 오답 단어만 연다', (tester) async {
    records.notes.addAll([
      fakeNote('ee-001', Cell.elementaryEasy),
      fakeNote('ee-004', Cell.elementaryEasy),
    ]);
    await openWrongNotes(tester);

    await tester.tap(find.byKey(const ValueKey('wrong-study')));
    await tester.pumpAndSettle();

    expect(find.byType(StudyScreen), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('apple'), findsOneWidget); // 파일 순서
  });

  testWidgets('오답이 없으면 비어 있다고 알린다', (tester) async {
    records.notes.add(fakeNote('eh-001', Cell.elementaryHard)); // 다른 칸만 있음
    await openWrongNotes(tester);

    expect(find.byKey(const ValueKey('wrong-empty')), findsOneWidget);
  });
}
