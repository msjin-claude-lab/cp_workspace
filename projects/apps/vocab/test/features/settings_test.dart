import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vocab/data/app_settings.dart';
import 'package:vocab/data/cell.dart';
import 'package:vocab/data/cell_store.dart';
import 'package:vocab/data/speaker.dart';
import 'package:vocab/data/study_decks.dart';
import 'package:vocab/data/study_records.dart';
import 'package:vocab/data/word.dart';
import 'package:vocab/data/word_repository.dart';
import 'package:vocab/features/quiz/quiz.dart' show quizRandomProvider;
import 'package:vocab/features/quiz/quiz_screen.dart';
import 'package:vocab/features/study/study_screen.dart';
import 'package:vocab/router.dart';

import '../fakes.dart';

void main() {
  late FakeAppSettingsStore settings;
  late FakeRecords records;

  List<Word> wordsOf(int n) => [
    for (var i = 0; i < n; i++) fakeWord('ee-$i', 'w$i', '뜻$i'),
  ];

  /// `home`이 null이면 앱 전체(홈에서 시작), 아니면 그 화면만 연다.
  Future<void> pump(
    WidgetTester tester,
    Widget? home, {
    int words = 50,
    Key? appKey,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        key: appKey,
        overrides: [
          wordRepositoryProvider.overrideWithValue(
            FakeRepository({Cell.elementaryEasy: wordsOf(words)}),
          ),
          appSettingsStoreProvider.overrideWithValue(settings),
          studyRecordsProvider.overrideWithValue(records),
          speakerProvider.overrideWithValue(FakeSpeaker()),
          // 카드·시험 순서는 무작위 — 개수만 보는 시험이라 순서는 고정해 둔다
          quizRandomProvider.overrideWithValue(NoShuffleRandom()),
          cellStoreProvider.overrideWithValue(FakeCellStore(selectedDeck: 1)),
          studyDecksProvider.overrideWithValue(
            FakeStudyDecks()..seed('아침 단어', Cell.elementaryEasy),
          ),
        ],
        child: home == null
            ? MaterialApp.router(routerConfig: createRouter())
            : MaterialApp(home: home),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    settings = FakeAppSettingsStore();
    records = FakeRecords();
  });

  SegmentedButton<int> segmented(WidgetTester tester, {required bool card}) =>
      tester.widget<SegmentedButton<int>>(
        find.byType(SegmentedButton<int>).at(card ? 0 : 1),
      );

  testWidgets('홈의 진도 바로 아래에 설정 버튼이 있고 누르면 설정 화면이 열린다', (tester) async {
    await pump(tester, null);
    final progress = tester.getTopLeft(
      find.byKey(const ValueKey('home-progress')),
    );
    final button = tester.getTopLeft(
      find.byKey(const ValueKey('home-settings')),
    );
    expect(button.dy, greaterThan(progress.dy));

    await tester.tap(find.byKey(const ValueKey('home-settings')));
    await tester.pumpAndSettle();
    expect(find.text('카드 학습 단어 수'), findsOneWidget);
    expect(find.text('시험 문항 수'), findsOneWidget);
    expect(find.text('한 번에 볼 카드 수'), findsOneWidget);
    expect(find.text('한 번에 풀 문제 수'), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-note')), findsOneWidget);
    // 기본값
    expect(segmented(tester, card: true).selected, {50});
    expect(segmented(tester, card: false).selected, {20});

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-settings')), findsOneWidget);
  });

  testWidgets('값을 고르면 바로 저장되고, 앱을 다시 만들어도 남아 있다', (tester) async {
    await pump(tester, null);
    await tester.tap(find.byKey(const ValueKey('home-settings')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('settings-card-10')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('settings-quiz-30')));
    await tester.pumpAndSettle();
    expect(settings.cardCount, 10);
    expect(settings.quizCount, 30);

    // 앱을 새로 만든다(재시작). 저장소는 그대로
    await pump(tester, null, appKey: UniqueKey());
    await tester.tap(find.byKey(const ValueKey('home-settings')));
    await tester.pumpAndSettle();
    expect(segmented(tester, card: true).selected, {10});
    expect(segmented(tester, card: false).selected, {30});
  });

  testWidgets('저장하지 못하면 안내하고, 이번 실행에서는 고른 값을 쓴다', (tester) async {
    settings.fail = true;
    await pump(tester, null);
    await tester.tap(find.byKey(const ValueKey('home-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('settings-card-20')));
    await tester.pumpAndSettle();
    expect(find.textContaining('설정을 저장하지 못했습니다'), findsOneWidget);
    expect(segmented(tester, card: true).selected, {20});
    expect(settings.cardCount, isNull);
  });

  group('직접 입력', () {
    Future<void> openSettings(WidgetTester tester) async {
      await pump(tester, null);
      await tester.tap(find.byKey(const ValueKey('home-settings')));
      await tester.pumpAndSettle();
    }

    Future<void> openDialog(WidgetTester tester, String prefix) async {
      await tester.tap(find.byKey(ValueKey('$prefix-custom')));
      await tester.pumpAndSettle();
    }

    Future<void> typeAndSave(
      WidgetTester tester,
      String prefix,
      String s,
    ) async {
      await tester.enterText(find.byKey(ValueKey('$prefix-input')), s);
      await tester.tap(find.byKey(ValueKey('$prefix-save')));
      await tester.pumpAndSettle();
    }

    ChoiceChip chip(WidgetTester tester, String prefix) =>
        tester.widget<ChoiceChip>(find.byKey(ValueKey('$prefix-custom')));

    testWidgets('45를 넣고 저장하면 직접 입력 (45)가 선택되고 저장·유지된다', (tester) async {
      await openSettings(tester);
      expect(find.text('직접 입력'), findsNWidgets(2));
      await openDialog(tester, 'settings-card');
      // 지금 값이 미리 채워져 있다
      expect(find.widgetWithText(TextField, '50'), findsOneWidget);
      await typeAndSave(tester, 'settings-card', '45');
      expect(find.text('직접 입력 (45)'), findsOneWidget);
      expect(chip(tester, 'settings-card').selected, isTrue);
      expect(segmented(tester, card: true).selected, isEmpty);
      expect(settings.cardCount, 45);

      await pump(tester, null, appKey: UniqueKey());
      await tester.tap(find.byKey(const ValueKey('home-settings')));
      await tester.pumpAndSettle();
      expect(find.text('직접 입력 (45)'), findsOneWidget);
      expect(chip(tester, 'settings-card').selected, isTrue);
    });

    testWidgets('잘못된 입력은 안내하고 창을 닫지 않는다', (tester) async {
      await openSettings(tester);
      await openDialog(tester, 'settings-quiz');
      for (final bad in ['', '0', '1000']) {
        await typeAndSave(tester, 'settings-quiz', bad);
        expect(find.text('1에서 999 사이의 숫자를 입력하세요'), findsOneWidget, reason: bad);
        expect(
          find.byKey(const ValueKey('settings-quiz-input')),
          findsOneWidget,
        );
      }
      expect(settings.quizCount, isNull);
    });

    testWidgets('숫자 이외의 글자는 들어가지 않는다', (tester) async {
      await openSettings(tester);
      await openDialog(tester, 'settings-card');
      await tester.enterText(
        find.byKey(const ValueKey('settings-card-input')),
        'a1b2',
      );
      expect(find.widgetWithText(TextField, '12'), findsOneWidget);
    });

    testWidgets('취소하면 값이 그대로다', (tester) async {
      settings.cardCount = 30;
      await openSettings(tester);
      await openDialog(tester, 'settings-card');
      await tester.enterText(
        find.byKey(const ValueKey('settings-card-input')),
        '77',
      );
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(segmented(tester, card: true).selected, {30});
      expect(settings.cardCount, 30);
    });

    testWidgets('직접 입력한 뒤 다시 눌러 바꾸고, 프리셋으로 돌아갈 수 있다', (tester) async {
      await openSettings(tester);
      await openDialog(tester, 'settings-card');
      await typeAndSave(tester, 'settings-card', '45');
      await openDialog(tester, 'settings-card');
      expect(find.widgetWithText(TextField, '45'), findsOneWidget);
      await typeAndSave(tester, 'settings-card', '60');
      expect(find.text('직접 입력 (60)'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('settings-card-20')));
      await tester.pumpAndSettle();
      expect(segmented(tester, card: true).selected, {20});
      expect(chip(tester, 'settings-card').selected, isFalse);
      expect(find.text('직접 입력'), findsNWidgets(2));
      expect(settings.cardCount, 20);
    });

    testWidgets('폭 360dp 폰에서도 넘치지 않는다', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      settings.cardCount = 999;
      settings.quizCount = 888;
      await openSettings(tester);
      expect(find.text('직접 입력 (999)'), findsOneWidget);
      expect(find.text('직접 입력 (888)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('카드 학습은 직접 입력한 수를 따른다', (tester) async {
      settings.cardCount = 7;
      await pump(tester, const StudyScreen(deck: Cell.elementaryEasy));
      expect(find.text('1 / 7'), findsOneWidget);
    });

    testWidgets('시험은 직접 입력한 수를 따른다', (tester) async {
      settings.quizCount = 7;
      await pump(tester, const QuizScreen(deck: Cell.elementaryEasy));
      expect(find.text('1 / 7'), findsOneWidget);
    });

    testWidgets('단어보다 큰 직접 입력 수는 있는 단어를 모두 쓴다', (tester) async {
      settings.cardCount = 999;
      settings.quizCount = 999;
      await pump(
        tester,
        const StudyScreen(deck: Cell.elementaryEasy),
        words: 12,
      );
      expect(find.text('1 / 12'), findsOneWidget);
      await pump(
        tester,
        const QuizScreen(deck: Cell.elementaryEasy),
        words: 12,
        appKey: UniqueKey(),
      );
      expect(find.text('1 / 12'), findsOneWidget);
    });
  });

  group('카드 학습', () {
    const screen = StudyScreen(deck: Cell.elementaryEasy);

    testWidgets('기본은 50장이다', (tester) async {
      await pump(tester, screen);
      expect(find.text('1 / 50'), findsOneWidget);
    });

    testWidgets('설정한 수만큼만 보이고, 끝 문구도 그 수다', (tester) async {
      settings.cardCount = 10;
      await pump(tester, screen);
      expect(find.text('1 / 10'), findsOneWidget);
      for (var i = 0; i < 10; i++) {
        await tester.tap(find.byKey(const ValueKey('study-next')));
        await tester.pumpAndSettle();
      }
      expect(find.text('10단어를 모두 봤습니다'), findsOneWidget);
    });

    testWidgets('단어가 설정보다 적으면 있는 단어를 모두 쓴다', (tester) async {
      settings.cardCount = 30;
      await pump(tester, screen, words: 12);
      expect(find.text('1 / 12'), findsOneWidget);
    });
  });

  group('시험', () {
    const screen = QuizScreen(deck: Cell.elementaryEasy);

    testWidgets('기본은 20문항이다', (tester) async {
      await pump(tester, screen);
      expect(find.text('1 / 20'), findsOneWidget);
    });

    testWidgets('설정한 수만큼 낸다', (tester) async {
      settings.quizCount = 10;
      await pump(tester, screen);
      expect(find.text('1 / 10'), findsOneWidget);
    });

    testWidgets('단어가 설정보다 적으면 있는 단어를 모두 쓴다', (tester) async {
      settings.quizCount = 30;
      await pump(tester, screen, words: 12);
      expect(find.text('1 / 12'), findsOneWidget);
    });

    testWidgets('오답 시험도 설정한 수만큼 낸다', (tester) async {
      settings.quizCount = 10;
      records.notes.addAll([
        for (var i = 0; i < 30; i++) fakeNote('ee-$i', Cell.elementaryEasy),
      ]);
      await pump(
        tester,
        const QuizScreen(deck: Cell.elementaryEasy, review: true),
      );
      expect(find.text('1 / 10'), findsOneWidget);
    });

    testWidgets('오답 노트가 설정보다 적으면 노트의 단어를 모두 낸다', (tester) async {
      settings.quizCount = 10;
      records.notes.addAll([
        for (var i = 0; i < 6; i++) fakeNote('ee-$i', Cell.elementaryEasy),
      ]);
      await pump(
        tester,
        const QuizScreen(deck: Cell.elementaryEasy, review: true),
      );
      expect(find.text('1 / 6'), findsOneWidget);
    });
  });
}
