import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vocab/data/app_settings.dart';
import 'package:vocab/data/cell.dart';
import 'package:vocab/data/cell_store.dart';
import 'package:vocab/data/counts.dart';
import 'package:vocab/data/speaker.dart';
import 'package:vocab/data/study_decks.dart';
import 'package:vocab/data/study_records.dart';
import 'package:vocab/data/word.dart';
import 'package:vocab/data/word_repository.dart';
import 'package:vocab/features/quiz/quiz.dart' show quizRandomProvider;
import 'package:vocab/features/quiz/quiz_screen.dart';
import 'package:vocab/features/study/study_screen.dart';
import 'package:vocab/router.dart';

import 'package:vocab/data/reminder_settings.dart';
import 'package:vocab/features/reminder/reminder_notifications.dart';

import '../fakes.dart';

/// 설정은 단어장마다 따로(2026-11-22 사용자 결정 — "설정은 그 단어장의 고유 설정이다").
void main() {
  /// 옛 공통 설정(7판 전, 읽기만).
  late FakeLegacySettingsStore legacy;
  late FakeRecords records;
  late FakeStudyDecks decks;
  late FakeReminderSettingsStore reminderStore;
  late FakeReminderNotifications notifications;

  /// 홈에서 여는 단어장(아침 단어)과 다른 단어장(저녁 단어). 둘 다 7판에서 만든 것(고유 값 50·20).
  late StudyDeck deck;
  late StudyDeck other;

  List<Word> wordsOf(int n) => [
    for (var i = 0; i < n; i++) fakeWord('ee-$i', 'w$i', '뜻$i'),
  ];

  /// `home`이 null이면 앱 전체(실제 `createRouter()`, `location`이 있으면 그 주소부터), 아니면 그 화면만 연다.
  Future<void> pump(
    WidgetTester tester,
    Widget? home, {
    int words = 50,
    Key? appKey,
    String? location,
  }) async {
    // 세로로 긴 폰 화면(설정에 오늘의 단어 개수·매일 알림이 더해져 길어졌다)
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = createRouter();
    if (location != null) router.go(location);
    await tester.pumpWidget(
      ProviderScope(
        key: appKey,
        overrides: [
          wordRepositoryProvider.overrideWithValue(
            FakeRepository({Cell.elementaryEasy: wordsOf(words)}),
          ),
          legacySettingsStoreProvider.overrideWithValue(legacy),
          studyRecordsProvider.overrideWithValue(records),
          speakerProvider.overrideWithValue(FakeSpeaker()),
          // 카드·시험 순서는 무작위 — 개수만 보는 시험이라 순서는 고정해 둔다
          quizRandomProvider.overrideWithValue(NoShuffleRandom()),
          cellStoreProvider.overrideWithValue(
            FakeCellStore(selectedDeck: deck.deckId),
          ),
          studyDecksProvider.overrideWithValue(decks),
          reminderSettingsStoreProvider.overrideWithValue(reminderStore),
          reminderNotificationsProvider.overrideWithValue(notifications),
        ],
        child: home == null
            ? MaterialApp.router(routerConfig: router)
            : MaterialApp(home: home),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String key) async {
    // 홈에 오늘의 단어 버튼이 생겨 아래 버튼·설정 항목이 화면 밖에 있을 수 있다 — 사람처럼 스크롤해 보이게 한 뒤 누른다
    await tester.ensureVisible(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
  }

  setUp(() {
    reminderStore = FakeReminderSettingsStore();
    notifications = FakeReminderNotifications();
    legacy = FakeLegacySettingsStore();
    records = FakeRecords();
    decks = FakeStudyDecks(records);
    deck = decks.seed(
      '아침 단어',
      Cell.elementaryEasy,
      cardCount: 50,
      quizCount: 20,
    );
    other = decks.seed(
      '저녁 단어',
      Cell.elementaryEasy,
      cardCount: 50,
      quizCount: 20,
    );
  });

  SegmentedButton<int> segmented(WidgetTester tester, {required bool card}) =>
      // 설정이 길어져(오늘의 단어 개수·매일 알림) 스크롤하면 위쪽 버튼이 빠질 수 있다 — 순서가 아니라 그 줄의 키로 찾는다
      tester.widget<SegmentedButton<int>>(
        find.ancestor(
          of: find.byKey(ValueKey(card ? 'settings-card-10' : 'settings-quiz-10')),
          matching: find.byType(SegmentedButton<int>),
        ),
      );

  testWidgets('홈의 진도 바로 아래에 설정 버튼이 있고 누르면 그 단어장의 설정 화면이 열린다', (tester) async {
    await pump(tester, null);
    final progress = tester.getTopLeft(
      find.byKey(const ValueKey('home-progress')),
    );
    final button = tester.getTopLeft(
      find.byKey(const ValueKey('home-settings')),
    );
    expect(button.dy, greaterThan(progress.dy));

    await tap(tester, 'home-settings');
    // 제목은 다른 안쪽 화면과 같은 꼴(한 줄, 넘치면 줄임표)
    final title = tester.widget<Text>(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('아침 단어 - 설정'),
      ),
    );
    expect(title.maxLines, 1);
    expect(title.overflow, TextOverflow.ellipsis);
    expect(find.text('카드 학습 단어 수'), findsOneWidget);
    expect(find.text('시험 문항 수'), findsOneWidget);
    expect(find.text('한 번에 볼 카드 수'), findsOneWidget);
    expect(find.text('한 번에 풀 문제 수'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('settings-note'))).data,
      '이 단어장에만 적용됩니다. 단어가 더 적으면 있는 단어를 모두 씁니다',
    );
    // 기본값
    expect(segmented(tester, card: true).selected, {50});
    expect(segmented(tester, card: false).selected, {20});

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-settings')), findsOneWidget);
  });

  testWidgets('홈의 단어 수 아래 줄에 카드 수·문항 수가 보이고, 설정을 바꾸고 돌아오면 바로 바뀐다', (
    tester,
  ) async {
    await pump(tester, null);
    String line() =>
        tester.widget<Text>(find.byKey(const ValueKey('home-counts'))).data!;
    expect(find.text('50단어'), findsOneWidget);
    expect(line(), '한 번에 카드 50장 · 시험 20문제');
    // 단어 수 줄 바로 아래
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('home-counts'))).dy,
      greaterThan(
        tester.getTopLeft(find.byKey(const ValueKey('home-word-count'))).dy,
      ),
    );

    await tap(tester, 'home-settings');
    await tap(tester, 'settings-card-10');
    await tap(tester, 'settings-quiz-30');
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(line(), '한 번에 카드 10장 · 시험 30문제');
  });

  testWidgets('홈 첫 줄(학교급)은 아래 두 줄보다 크고 단어장 이름보다 작다', (tester) async {
    await pump(tester, null);
    // 실제로 그려진 글자 크기(테마까지 반영된 값)를 본다
    double sizeOf(Finder text) => tester
        .widget<RichText>(
          find.descendant(of: text, matching: find.byType(RichText)),
        )
        .text
        .style!
        .fontSize!;
    final name = sizeOf(
      find.descendant(of: find.byType(AppBar), matching: find.text('아침 단어')),
    );
    final base = sizeOf(find.byKey(const ValueKey('home-base')));
    final count = sizeOf(find.byKey(const ValueKey('home-word-count')));
    final counts = sizeOf(find.byKey(const ValueKey('home-counts')));

    expect(base, lessThan(name));
    expect(base, greaterThan(count));
    expect(counts, count);
  });

  testWidgets('홈 셋째 줄은 설정을 읽는 동안 숨었다가 읽으면 보이고, 단어장을 바꾸면 그 단어장 값이 보인다', (
    tester,
  ) async {
    decks.cardCounts[other.deckId] = 10;
    final gate = Completer<void>();
    decks.loadGate = gate.future;
    await pump(tester, null);

    // 설정을 아직 못 읽음 — 단어 수만 보이고 엉뚱한 수는 보이지 않는다
    expect(find.text('50단어'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-counts')), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();
    String line() =>
        tester.widget<Text>(find.byKey(const ValueKey('home-counts'))).data!;
    expect(line(), '한 번에 카드 50장 · 시험 20문제');

    decks.loadGate = null;
    await tap(tester, 'menu');
    await tap(tester, 'menu-deck-${other.deckId}');
    expect(line(), '한 번에 카드 10장 · 시험 20문제');
  });

  testWidgets('홈의 카드 수·문항 수는 단어가 설정보다 적으면 있는 만큼으로 보인다', (tester) async {
    await pump(tester, null, words: 12);

    expect(
      tester.widget<Text>(find.byKey(const ValueKey('home-counts'))).data,
      '한 번에 카드 12장 · 시험 12문제',
    );
  });

  testWidgets('값을 고르면 그 단어장에 바로 저장되고, 앱을 다시 만들어도 남아 있다', (tester) async {
    await pump(tester, null);
    await tap(tester, 'home-settings');

    await tap(tester, 'settings-card-10');
    await tap(tester, 'settings-quiz-30');
    expect(decks.cardCounts[deck.deckId], 10);
    expect(decks.quizCounts[deck.deckId], 30);
    // 다른 단어장과 옛 공통 설정은 그대로
    expect(decks.cardCounts[other.deckId], 50);
    expect(decks.quizCounts[other.deckId], 20);
    expect(legacy.cardCount, isNull);
    expect(legacy.quizCount, isNull);

    // 앱을 새로 만든다(재시작). 저장소는 그대로
    await pump(tester, null, appKey: UniqueKey());
    await tap(tester, 'home-settings');
    expect(segmented(tester, card: true).selected, {10});
    expect(segmented(tester, card: false).selected, {30});
  });

  testWidgets('단어장 A에서 10으로 바꾼 뒤 B로 바꿔 열면 B는 그대로이고, 카드 학습은 각자 자기 값을 따른다', (
    tester,
  ) async {
    decks.cardCounts[other.deckId] = 30;
    await pump(tester, null);
    await tap(tester, 'home-settings');
    await tap(tester, 'settings-card-10');
    await tester.pageBack();
    await tester.pumpAndSettle();

    // ☰ 메뉴로 B(저녁 단어)를 홈으로
    await tap(tester, 'menu');
    await tap(tester, 'menu-deck-${other.deckId}');
    await tap(tester, 'home-settings');
    expect(find.text('저녁 단어 - 설정'), findsOneWidget);
    expect(segmented(tester, card: true).selected, {30});
    expect(segmented(tester, card: false).selected, {20});
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tap(tester, 'home-study');
    expect(find.text('1 / 30'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 다시 A로
    await tap(tester, 'menu');
    await tap(tester, 'menu-deck-${deck.deckId}');
    await tap(tester, 'home-study');
    expect(find.text('1 / 10'), findsOneWidget);
    expect(decks.cardCounts, {deck.deckId: 10, other.deckId: 30});
  });

  testWidgets('7판 전에 있던 단어장은 옛 공통 설정값을 보여 주고, 바꾸면 그 값만 그 단어장에 저장된다', (
    tester,
  ) async {
    decks.cardCounts.remove(deck.deckId);
    decks.quizCounts.remove(deck.deckId);
    legacy
      ..cardCount = 30
      ..quizCount = 10;
    await pump(tester, null);
    await tap(tester, 'home-settings');
    expect(segmented(tester, card: true).selected, {30});
    expect(segmented(tester, card: false).selected, {10});

    await tap(tester, 'settings-card-20');
    expect(decks.cardCounts[deck.deckId], 20);
    expect(decks.quizCounts[deck.deckId], isNull, reason: '문항 수는 계속 물려받는다');
    expect(legacy.cardCount, 30, reason: '옛 공통 설정은 읽기만 한다');
    expect(segmented(tester, card: false).selected, {10});
  });

  testWidgets('저장하지 못하면 안내하고, 이번 실행에서는 고른 값을 쓴다', (tester) async {
    decks.failSave = true;
    await pump(tester, null);
    await tap(tester, 'home-settings');
    await tap(tester, 'settings-card-20');
    expect(find.textContaining('설정을 저장하지 못했습니다'), findsOneWidget);
    expect(segmented(tester, card: true).selected, {20});
    expect(decks.cardCounts[deck.deckId], 50);
  });

  testWidgets('설정 주소의 단어장이 없거나 내장 칸이면 찾을 수 없다고 보인다', (tester) async {
    await pump(tester, null, location: '/settings/deck_99');
    expect(find.text('찾을 수 없는 화면입니다'), findsOneWidget);
    await pump(
      tester,
      null,
      location: '/settings/elementary_easy',
      appKey: UniqueKey(),
    );
    expect(find.text('찾을 수 없는 화면입니다'), findsOneWidget);
  });

  // 100과 카드 학습 "전체"(2026-11-24 사용자 결정 — "카드수·문항수 각각 100도, 카드수는 최대(단어수)도")
  group('100과 전체', () {
    ChoiceChip allChip(WidgetTester tester) => tester.widget<ChoiceChip>(
      find.byKey(const ValueKey('settings-card-all')),
    );

    testWidgets('카드 수·문항 수에서 100을 고르면 그 단어장에 저장되고 그 조각이 선택된다', (tester) async {
      await pump(tester, null);
      await tap(tester, 'home-settings');
      await tap(tester, 'settings-card-100');
      await tap(tester, 'settings-quiz-100');
      expect(decks.cardCounts[deck.deckId], 100);
      expect(decks.quizCounts[deck.deckId], 100);
      expect(segmented(tester, card: true).selected, {100});
      expect(segmented(tester, card: false).selected, {100});
    });

    testWidgets('카드 수에만 단어 수를 보인 전체가 있고, 고르면 저장되고 전체만 선택된다', (tester) async {
      await pump(tester, null, words: 120);
      await tap(tester, 'home-settings');
      expect(find.text('전체 (120)'), findsOneWidget);
      expect(find.byKey(const ValueKey('settings-quiz-all')), findsNothing);

      await tap(tester, 'settings-card-all');
      expect(decks.cardCounts[deck.deckId], allCardsCount);
      expect(allChip(tester).selected, isTrue);
      expect(segmented(tester, card: true).selected, isEmpty);
      // 전체는 직접 입력이 아니다
      expect(
        tester
            .widget<ChoiceChip>(
              find.byKey(const ValueKey('settings-card-custom')),
            )
            .selected,
        isFalse,
      );
      expect(find.text('직접 입력'), findsNWidgets(2));

      // 다시 조각을 고르면 전체가 풀린다
      await tap(tester, 'settings-card-30');
      expect(allChip(tester).selected, isFalse);
      expect(decks.cardCounts[deck.deckId], 30);
    });

    testWidgets('전체이면 카드 학습은 그 단어장의 단어를 모두 쓰고, 홈도 단어 수만큼으로 보인다', (
      tester,
    ) async {
      decks.cardCounts[deck.deckId] = allCardsCount;
      await pump(tester, null, words: 120);
      expect(find.text('한 번에 카드 120장 · 시험 20문제'), findsOneWidget);
      await pump(
        tester,
        StudyScreen(deck: deck),
        words: 120,
        appKey: UniqueKey(),
      );
      expect(find.text('1 / 120'), findsOneWidget);
    });

    testWidgets('직접 입력 창은 전체의 저장값(9999)을 받지 않는다 — 카드도 문항도 1~999만', (
      tester,
    ) async {
      await pump(tester, null);
      await tap(tester, 'home-settings');
      for (final prefix in ['settings-card', 'settings-quiz']) {
        await tap(tester, '$prefix-custom');
        await tester.enterText(
          find.byKey(ValueKey('$prefix-input')),
          '$allCardsCount',
        );
        await tap(tester, '$prefix-save');
        expect(find.text('1에서 999 사이의 숫자를 입력하세요'), findsOneWidget);
        await tester.tap(find.text('취소'));
        await tester.pumpAndSettle();
      }
      expect(decks.cardCounts[deck.deckId], 50);
      expect(decks.quizCounts[deck.deckId], 20);
    });

    testWidgets('전체로 저장한 단어장은 앱을 다시 만들어도 전체가 선택된다, 문항 수에 9999가 있으면 기본값으로 본다', (
      tester,
    ) async {
      decks.cardCounts[deck.deckId] = allCardsCount;
      decks.quizCounts[deck.deckId] = allCardsCount;
      await pump(tester, null, words: 120);
      await tap(tester, 'home-settings');
      expect(allChip(tester).selected, isTrue);
      expect(segmented(tester, card: false).selected, {defaultQuizCount});
    });

    testWidgets('전체에서 직접 입력을 열면 9999가 아니라 기본값부터 보인다', (tester) async {
      decks.cardCounts[deck.deckId] = allCardsCount;
      await pump(tester, null);
      await tap(tester, 'home-settings');
      await tap(tester, 'settings-card-custom');
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('settings-card-input')),
            )
            .controller!
            .text,
        '$defaultCardCount',
      );
    });

    testWidgets('폭 360dp 폰에서 조각 다섯 개와 전체·직접 입력이 넘치지 않는다', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      decks.cardCounts[deck.deckId] = allCardsCount;
      await pump(tester, null, words: 500);
      await tap(tester, 'home-settings');
      expect(find.text('전체 (500)'), findsOneWidget);
      expect(find.text('100'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  });

  group('직접 입력', () {
    Future<void> openSettings(WidgetTester tester) async {
      await pump(tester, null);
      await tap(tester, 'home-settings');
    }

    Future<void> openDialog(WidgetTester tester, String prefix) =>
        tap(tester, '$prefix-custom');

    Future<void> typeAndSave(
      WidgetTester tester,
      String prefix,
      String s,
    ) async {
      await tester.enterText(find.byKey(ValueKey('$prefix-input')), s);
      await tap(tester, '$prefix-save');
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
      expect(decks.cardCounts[deck.deckId], 45);

      await pump(tester, null, appKey: UniqueKey());
      await tap(tester, 'home-settings');
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
      expect(decks.quizCounts[deck.deckId], 20);
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
      decks.cardCounts[deck.deckId] = 30;
      await openSettings(tester);
      await openDialog(tester, 'settings-card');
      await tester.enterText(
        find.byKey(const ValueKey('settings-card-input')),
        '77',
      );
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(segmented(tester, card: true).selected, {30});
      expect(decks.cardCounts[deck.deckId], 30);
    });

    testWidgets('직접 입력한 뒤 다시 눌러 바꾸고, 프리셋으로 돌아갈 수 있다', (tester) async {
      await openSettings(tester);
      await openDialog(tester, 'settings-card');
      await typeAndSave(tester, 'settings-card', '45');
      await openDialog(tester, 'settings-card');
      expect(find.widgetWithText(TextField, '45'), findsOneWidget);
      await typeAndSave(tester, 'settings-card', '60');
      expect(find.text('직접 입력 (60)'), findsOneWidget);

      await tap(tester, 'settings-card-20');
      expect(segmented(tester, card: true).selected, {20});
      expect(chip(tester, 'settings-card').selected, isFalse);
      expect(find.text('직접 입력'), findsNWidgets(2));
      expect(decks.cardCounts[deck.deckId], 20);
    });

    testWidgets('폭 360dp 폰에서도 넘치지 않는다', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      decks.cardCounts[deck.deckId] = 999;
      decks.quizCounts[deck.deckId] = 888;
      await openSettings(tester);
      expect(find.text('직접 입력 (999)'), findsOneWidget);
      expect(find.text('직접 입력 (888)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('카드 학습은 그 단어장에 직접 입력한 수를 따른다', (tester) async {
      decks.cardCounts[deck.deckId] = 7;
      await pump(tester, StudyScreen(deck: deck));
      expect(find.text('1 / 7'), findsOneWidget);
    });

    testWidgets('시험은 그 단어장에 직접 입력한 수를 따른다', (tester) async {
      decks.quizCounts[deck.deckId] = 7;
      await pump(tester, QuizScreen(deck: deck));
      expect(find.text('1 / 7'), findsOneWidget);
    });

    testWidgets('단어보다 큰 직접 입력 수는 있는 단어를 모두 쓴다', (tester) async {
      decks.cardCounts[deck.deckId] = 999;
      decks.quizCounts[deck.deckId] = 999;
      await pump(tester, StudyScreen(deck: deck), words: 12);
      expect(find.text('1 / 12'), findsOneWidget);
      await pump(
        tester,
        QuizScreen(deck: deck),
        words: 12,
        appKey: UniqueKey(),
      );
      expect(find.text('1 / 12'), findsOneWidget);
    });
  });

  group('카드 학습', () {
    testWidgets('기본은 50장이다', (tester) async {
      await pump(tester, StudyScreen(deck: deck));
      expect(find.text('1 / 50'), findsOneWidget);
    });

    testWidgets('그 단어장에 설정한 수만큼만 보이고, 끝 문구도 그 수다', (tester) async {
      decks.cardCounts[deck.deckId] = 10;
      await pump(tester, StudyScreen(deck: deck));
      expect(find.text('1 / 10'), findsOneWidget);
      for (var i = 0; i < 10; i++) {
        await tap(tester, 'study-next');
      }
      expect(find.text('10단어를 모두 봤습니다'), findsOneWidget);
    });

    testWidgets('단어가 설정보다 적으면 있는 단어를 모두 쓴다', (tester) async {
      decks.cardCounts[deck.deckId] = 30;
      await pump(tester, StudyScreen(deck: deck), words: 12);
      expect(find.text('1 / 12'), findsOneWidget);
    });

    testWidgets('내장 칸을 직접 열면 옛 공통 설정값을, 없으면 기본값을 쓴다', (tester) async {
      legacy.cardCount = 7;
      await pump(tester, const StudyScreen(deck: Cell.elementaryEasy));
      expect(find.text('1 / 7'), findsOneWidget);
      legacy.cardCount = null;
      await pump(
        tester,
        const StudyScreen(deck: Cell.elementaryEasy),
        appKey: UniqueKey(),
      );
      expect(find.text('1 / 50'), findsOneWidget);
    });
  });

  group('시험', () {
    testWidgets('기본은 20문항이다', (tester) async {
      await pump(tester, QuizScreen(deck: deck));
      expect(find.text('1 / 20'), findsOneWidget);
    });

    testWidgets('그 단어장에 설정한 수만큼 낸다', (tester) async {
      decks.quizCounts[deck.deckId] = 10;
      decks.quizCounts[other.deckId] = 30;
      await pump(tester, QuizScreen(deck: deck));
      expect(find.text('1 / 10'), findsOneWidget);
    });

    testWidgets('단어가 설정보다 적으면 있는 단어를 모두 쓴다', (tester) async {
      decks.quizCounts[deck.deckId] = 30;
      await pump(tester, QuizScreen(deck: deck), words: 12);
      expect(find.text('1 / 12'), findsOneWidget);
    });

    testWidgets('오답 시험도 그 단어장에 설정한 수만큼 낸다(다른 단어장 값은 보지 않는다)', (tester) async {
      decks.quizCounts[deck.deckId] = 10;
      decks.quizCounts[other.deckId] = 30;
      records.notes.addAll([
        for (var i = 0; i < 30; i++) fakeNote('ee-$i', deck),
      ]);
      await pump(tester, QuizScreen(deck: deck, review: true));
      expect(find.text('1 / 10'), findsOneWidget);
    });

    testWidgets('오답 노트가 설정보다 적으면 노트의 단어를 모두 낸다', (tester) async {
      decks.quizCounts[deck.deckId] = 10;
      records.notes.addAll([
        for (var i = 0; i < 6; i++) fakeNote('ee-$i', deck),
      ]);
      await pump(tester, QuizScreen(deck: deck, review: true));
      expect(find.text('1 / 6'), findsOneWidget);
    });
  });
}
