import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vocara/data/app_settings.dart';
import 'package:vocara/data/cell.dart';
import 'package:vocara/data/cell_store.dart';
import 'package:vocara/data/speaker.dart';
import 'package:vocara/data/study_decks.dart';
import 'package:vocara/data/study_records.dart';
import 'package:vocara/data/word_repository.dart';
import 'package:vocara/features/quiz/quiz.dart';
import 'package:vocara/features/quiz/quiz_screen.dart';
import 'package:vocara/features/wrong_notes/wrong_notes_screen.dart';
import 'package:vocara/router.dart';

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
  late FakeStudyDecks decks;
  // 홈 단어장(초등 쉬움), 같은 초등 쉬움으로 만든 다른 단어장, 초등 어려움 단어장
  late StudyDeck home;
  late StudyDeck twin;
  late StudyDeck hard;

  setUp(() {
    records = FakeRecords();
    decks = FakeStudyDecks(records);
    home = decks.seed('아침 단어', Cell.elementaryEasy);
    twin = decks.seed('저녁 단어', Cell.elementaryEasy);
    hard = decks.seed('어려운 단어', Cell.elementaryHard);
  });

  /// 단어장 홈(기본은 아침 단어 — 초등 [난이도 : 쉬움])에서 오답 노트로 들어간다.
  Future<void> openWrongNotes(WidgetTester tester, {StudyDeck? deck}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          noBannerAds(),
          legacySettingsStoreProvider.overrideWithValue(FakeLegacySettingsStore()),
          wordRepositoryProvider.overrideWithValue(FakeRepository(words)),
          cellStoreProvider.overrideWithValue(
            FakeCellStore(selectedDeck: (deck ?? home).deckId),
          ),
          studyDecksProvider.overrideWithValue(decks),
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

  testWidgets('오답 노트는 그 단어장의 오답만, 최근에 틀린 것부터 틀린 횟수와 함께 보여 준다', (tester) async {
    records.notes.addAll([
      fakeNote('ee-001', home, miss: 2, at: 1),
      fakeNote('ee-003', home, at: 5),
      fakeNote('eh-001', hard, at: 9), // 다른 단어장 — 안 보인다
      fakeNote('ee-004', twin, at: 7), // 같은 초등 쉬움이라도 다른 단어장 — 안 보인다
    ]);
    await openWrongNotes(tester);

    expect(find.byType(WrongNotesScreen), findsOneWidget);
    expect(find.text('아침 단어 - 오답 노트'), findsOneWidget);
    expect(find.text('2단어'), findsOneWidget);
    expect(find.text('castle'), findsNothing);
    expect(find.text('desk'), findsNothing);
    expect(find.text('2회 틀림'), findsOneWidget);
    // 최근에 틀린 cup(5)이 apple(1)보다 위
    expect(
      tester.getTopLeft(find.text('cup')).dy,
      lessThan(tester.getTopLeft(find.text('apple')).dy),
    );
  });

  testWidgets('지우기를 누르면 오답 노트에서 빠지고, 홈의 오답 수도 바뀐다(다른 단어장의 같은 단어는 남는다)', (
    tester,
  ) async {
    records.notes.addAll([
      fakeNote('ee-001', home),
      fakeNote('ee-002', home),
      fakeNote('ee-001', twin),
    ]);
    await openWrongNotes(tester);

    await tester.tap(find.byKey(const ValueKey('wrong-delete-ee-001')));
    await tester.pumpAndSettle();

    expect(records.removed, ['ee-001']);
    expect(find.text('apple'), findsNothing);
    expect(find.text('1단어'), findsOneWidget);
    expect(find.text('apple — 오답 노트에서 지웠습니다'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('오답 노트 · 1단어'), findsOneWidget);
    expect(records.notes.where((n) => n.deck == twin).map((n) => n.wordId), [
      'ee-001',
    ]);
  });

  testWidgets('지운 뒤 되돌리기를 누르면 틀린 횟수와 시각 그대로 다시 생기고, 스낵바는 떠 있어 목록을 덮지 않는다', (
    tester,
  ) async {
    records.notes.addAll([
      fakeNote('ee-001', home, miss: 3, at: 7),
      fakeNote('ee-002', home, miss: 1, at: 5),
    ]);
    await openWrongNotes(tester);

    await tester.tap(find.byKey(const ValueKey('wrong-delete-ee-001')));
    await tester.pumpAndSettle();
    expect(find.text('apple'), findsNothing);
    expect(
      tester.widget<SnackBar>(find.byType(SnackBar)).behavior,
      SnackBarBehavior.floating,
    );

    await tester.tap(find.byKey(const ValueKey('wrong-undo')));
    await tester.pumpAndSettle();

    expect(find.text('apple'), findsOneWidget);
    expect(find.text('2단어'), findsOneWidget);
    final back = records.notes.singleWhere((n) => n.wordId == 'ee-001');
    expect((back.missCount, back.lastMissedAt), (3, 7));
    expect(find.text('3회 틀림'), findsOneWidget);
  });

  testWidgets('오답 시험에서 맞히면 돌아온 오답 노트에서 그 단어가 사라진다', (tester) async {
    records.notes.add(fakeNote('ee-002', home));
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

  testWidgets('오답 노트에는 오답 시험만 있고 카드로 다시 보기 버튼은 없다', (tester) async {
    records.notes.addAll([fakeNote('ee-001', home), fakeNote('ee-004', home)]);
    await openWrongNotes(tester);

    expect(find.byKey(const ValueKey('wrong-quiz')), findsOneWidget);
    expect(find.text('카드로 다시 보기'), findsNothing);
    expect(find.byKey(const ValueKey('wrong-study')), findsNothing);
  });

  testWidgets('오답이 없으면 비어 있다고 알린다', (tester) async {
    // 다른 단어장에만 있음
    records.notes.addAll([fakeNote('eh-001', hard), fakeNote('ee-001', twin)]);
    await openWrongNotes(tester);

    expect(find.byKey(const ValueKey('wrong-empty')), findsOneWidget);
  });

  // my_words_test.dart(내 단어장, 2026-11-22 지움)에서 옮겼다 — 보기 4개를 만들 수 없는 묶음
  testWidgets('단어가 4개보다 적은 단어장의 오답 노트는 오답 시험이 막히고 까닭을 알려 준다(지우기는 된다)', (
    tester,
  ) async {
    // 어려운 단어 단어장의 바탕 칸(초등 어려움)에는 단어가 1개뿐
    records.notes.add(fakeNote('eh-001', hard));
    await openWrongNotes(tester, deck: hard);

    expect(find.byKey(const ValueKey('wrong-quiz-locked')), findsOneWidget);
    expect(find.text('단어가 4개 이상 있어야 시험을 볼 수 있습니다'), findsOneWidget);
    await tapShown(tester, find.byKey(const ValueKey('wrong-quiz')));
    expect(find.byType(QuizScreen), findsNothing);

    await tapShown(tester, find.byKey(const ValueKey('wrong-delete-eh-001')));
    expect(records.removed, ['eh-001']);
    expect(find.byKey(const ValueKey('wrong-empty')), findsOneWidget);
  });
}
