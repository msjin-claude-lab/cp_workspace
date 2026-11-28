import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vocara/data/app_settings.dart';
import 'package:vocara/data/cell.dart';
import 'package:vocara/data/cell_store.dart';
import 'package:vocara/data/reminder_settings.dart';
import 'package:vocara/data/speaker.dart';
import 'package:vocara/data/study_decks.dart';
import 'package:vocara/data/study_records.dart';
import 'package:vocara/data/word.dart';
import 'package:vocara/data/word_repository.dart';
import 'package:vocara/features/quiz/quiz.dart' show quizRandomProvider;
import 'package:vocara/features/reminder/reminder_notifications.dart';
import 'package:vocara/features/today/today_words.dart';
import 'package:vocara/router.dart';

import '../fakes.dart';

/// 오늘의 단어(2026-11-28 사용자 결정): 홈의 카드 학습 바로 위 버튼, 단어장마다 하루 N개를 고정해 카드로 보고,
/// 다 보면 완료 ✓ — 진도 달력에도 ✓, 매일 알림은 오늘 것을 뺀다.
void main() {
  late FakeRecords records;
  late FakeStudyDecks decks;
  late FakeReminderSettingsStore reminderStore;
  late FakeReminderNotifications notifications;
  late StudyDeck deck;
  late DateTime now;
  late List<Word> words;

  setUp(() {
    records = FakeRecords();
    decks = FakeStudyDecks(records);
    deck = decks.seed('아침 단어', Cell.elementaryEasy);
    reminderStore = FakeReminderSettingsStore(
      settings: const ReminderSettings(enabled: true),
      asked: true,
    );
    notifications = FakeReminderNotifications(permitted: true);
    now = DateTime(2026, 11, 28, 9);
    words = [for (var i = 0; i < 3; i++) fakeWord('ee-$i', 'w$i', '뜻$i')];
  });

  /// 앱(실제 라우터)을 새로 만든다 — 저장소(가짜)는 그대로라 "앱을 다시 시작한 것"과 같다.
  Future<void> pumpApp(WidgetTester tester) async {
    // 홈 버튼 여섯 개와 설정 항목이 한 화면에 보이게 세로로 긴 화면
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const SizedBox()); // 앞 앱을 버린다
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          noBannerAds(),
          wordRepositoryProvider.overrideWithValue(
            FakeRepository({Cell.elementaryEasy: words}),
          ),
          legacySettingsStoreProvider.overrideWithValue(
            FakeLegacySettingsStore(),
          ),
          studyRecordsProvider.overrideWithValue(records),
          studyDecksProvider.overrideWithValue(decks),
          cellStoreProvider.overrideWithValue(
            FakeCellStore(selectedDeck: deck.deckId),
          ),
          speakerProvider.overrideWithValue(FakeSpeaker()),
          quizRandomProvider.overrideWithValue(NoShuffleRandom()),
          dailyRandomProvider.overrideWithValue(NoShuffleRandom()),
          nowProvider.overrideWithValue(() => now),
          reminderSettingsStoreProvider.overrideWithValue(reminderStore),
          reminderNotificationsProvider.overrideWithValue(notifications),
        ],
        child: MaterialApp.router(routerConfig: createRouter()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
  }

  String homeLabel(WidgetTester tester) => tester
      .widget<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('home-today')),
          matching: find.byType(Text),
        ),
      )
      .data!;

  /// 오늘의 단어 화면에서 카드를 끝까지 넘기며 앞면 단어를 모은다.
  Future<List<String>> seeAll(WidgetTester tester, int count) async {
    final seen = <String>[];
    for (var i = 0; i < count; i++) {
      final front = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('study-card')),
          matching: find.byType(Text),
        ),
      );
      seen.add(front.data!);
      await tap(tester, 'study-next');
    }
    return seen;
  }

  Future<void> back(WidgetTester tester) async {
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
  }

  testWidgets('홈의 오늘의 단어 버튼은 카드 학습 바로 위에 있고 처음에는 0/N(단어가 적으면 있는 만큼)', (
    tester,
  ) async {
    await pumpApp(tester);
    final today = tester.getRect(find.byKey(const ValueKey('home-today')));
    final study = tester.getRect(find.byKey(const ValueKey('home-study')));
    // 바로 위: 오늘의 단어 아래에 다른 버튼 없이 카드 학습이 온다
    expect(today.bottom, lessThanOrEqualTo(study.top));
    expect(study.top - today.bottom, lessThan(20));
    expect(homeLabel(tester), '오늘의 단어 · 0/3');
  });

  testWidgets('카드를 모두 넘기면 학습 기록이 남고 홈이 완료 ✓가 되며, 오늘 알림은 빠지고 내일부터 예약된다', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(notifications.scheduled, isNull); // 이 시험은 ReminderHost 없이 연다

    await tap(tester, 'home-today');
    expect(find.text('아침 단어 - 오늘의 단어'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    final seen = await seeAll(tester, 3);
    expect(seen.toSet(), {'w0', 'w1', 'w2'});
    expect(find.text('오늘의 단어 3개를 모두 봤습니다'), findsOneWidget);
    // 카드 학습과 똑같이 study_log에 남는다(진도에 들어간다)
    expect(records.studied.toSet(), {'ee-0', 'ee-1', 'ee-2'});
    expect((await records.progress(deck)).days.single.cards, 3);
    // 끝내는 순간 다시 예약: 오늘 20시가 아니라 내일 20시부터
    expect(notifications.scheduled!.first, DateTime(2026, 11, 29, 20));

    await back(tester);
    expect(homeLabel(tester), '오늘의 단어 · 완료 ✓');

    // 끝낸 뒤에도 눌러 다시 볼 수 있다(같은 단어, 같은 순서)
    await tap(tester, 'home-today');
    expect(await seeAll(tester, 3), seen);
    await back(tester);
    expect(homeLabel(tester), '오늘의 단어 · 완료 ✓');
  });

  testWidgets('중간에 나가면 홈은 본 수/N이고, 앱을 다시 시작해도 같은 단어가 같은 순서로 이어진다', (
    tester,
  ) async {
    words = [for (var i = 0; i < 12; i++) fakeWord('ee-$i', 'w$i', '뜻$i')];
    await pumpApp(tester);
    expect(homeLabel(tester), '오늘의 단어 · 0/10');

    await tap(tester, 'home-today');
    final first = await seeAll(tester, 1);
    await back(tester);
    await tap(tester, 'leave-exit');
    expect(homeLabel(tester), '오늘의 단어 · 1/10');

    // 앱을 다시 시작(같은 날)
    await pumpApp(tester);
    expect(homeLabel(tester), '오늘의 단어 · 1/10');
    await tap(tester, 'home-today');
    final again = await seeAll(tester, 2);
    expect(again.first, first.single); // 고른 순서 그대로 처음부터
    final set = decks.dailySets[(deck.deckId, '2026-11-28')]!;
    expect(set.wordIds, hasLength(10));
    expect(set.seenIds, hasLength(2));
  });

  testWidgets('자정이 지나면 새로 고른다 — 어제 본 단어보다 안 본 단어가 먼저', (tester) async {
    words = [for (var i = 0; i < 12; i++) fakeWord('ee-$i', 'w$i', '뜻$i')];
    await pumpApp(tester);
    await tap(tester, 'home-today');
    await seeAll(tester, 10);
    await back(tester);
    final yesterday = decks.dailySets[(deck.deckId, '2026-11-28')]!.wordIds;

    now = DateTime(2026, 11, 29, 0, 1);
    await pumpApp(tester);
    expect(homeLabel(tester), '오늘의 단어 · 0/10');
    final today = decks.dailySets[(deck.deckId, '2026-11-29')]!.wordIds;
    final unseen = {
      for (final w in words)
        if (!yesterday.contains(w.id)) w.id,
    };
    // 안 본 2개가 맨 앞, 나머지는 어제 본 것 중 오래전에 본 것부터
    expect(today.take(2).toSet(), unseen);
    expect(today.skip(2), yesterday.take(8));
    // 어제 묶음은 그대로 남는다
    expect(decks.dailySets[(deck.deckId, '2026-11-28')]!.completed, isTrue);
  });

  testWidgets('설정에서 개수를 5로 바꾸면 오늘 것은 그대로이고 다음 날부터 5개를 고른다', (tester) async {
    words = [for (var i = 0; i < 20; i++) fakeWord('ee-$i', 'w$i', '뜻$i')];
    await pumpApp(tester);
    expect(homeLabel(tester), '오늘의 단어 · 0/10');

    await tap(tester, 'home-settings');
    expect(find.text('오늘의 단어 개수'), findsOneWidget);
    expect(
      tester
          .widget<SegmentedButton<int>>(
            find.ancestor(
              of: find.byKey(const ValueKey('settings-daily-10')),
              matching: find.byType(SegmentedButton<int>),
            ),
          )
          .selected,
      {10},
    );
    await tap(tester, 'settings-daily-5');
    expect(decks.dailyCounts[deck.deckId], 5);
    await back(tester);
    expect(homeLabel(tester), '오늘의 단어 · 0/10');

    now = DateTime(2026, 11, 29, 9);
    await pumpApp(tester);
    expect(homeLabel(tester), '오늘의 단어 · 0/5');
  });

  testWidgets('설정 화면의 앱 전체 매일 알림: 켜기/끄기와 시각이 보이고, 권한이 거절되면 시스템 설정을 안내한다', (
    tester,
  ) async {
    reminderStore.settings = const ReminderSettings();
    notifications
      ..permitted = false
      ..grant = false;
    await pumpApp(tester);
    await tap(tester, 'home-settings');
    expect(find.text('앱 전체 — 매일 알림'), findsOneWidget);
    expect(find.text('20:00'), findsOneWidget);
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const ValueKey('reminder-switch')))
          .value,
      isFalse,
    );

    await tap(tester, 'reminder-switch');
    expect(notifications.requests, 1);
    expect(find.byKey(const ValueKey('reminder-denied')), findsOneWidget);
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const ValueKey('reminder-switch')))
          .value,
      isFalse,
    );
    await tester.tap(find.text('설정 열기'));
    await tester.pumpAndSettle();
    expect(notifications.settingsOpened, 1);

    // 시스템 설정에서 허용하고 돌아와 켜면 켜지고 예약된다
    notifications.permitted = true;
    await tap(tester, 'reminder-switch');
    expect(reminderStore.settings.enabled, isTrue);
    expect(notifications.scheduled!.first, DateTime(2026, 11, 28, 20));
  });

  testWidgets('진도 달력: 오늘의 단어를 끝낸 날은 점 대신 ✓, 범례에 "오늘의 단어 완료"', (tester) async {
    final today = dayKey(DateTime.now());
    final other = dayKey(DateTime.now().subtract(const Duration(days: 1)));
    decks.dailySets[(deck.deckId, today)] = DailySet(
      day: today,
      wordIds: const ['ee-0'],
      seenIds: const {'ee-0'},
    );
    // 다른 날은 끝내지 않았다(고른 것 중 하나만 봄)
    decks.dailySets[(deck.deckId, other)] = DailySet(
      day: other,
      wordIds: const ['ee-0', 'ee-1'],
      seenIds: const {'ee-0'},
    );
    await records.recordCardViewed(deck: deck, word: words.first);
    await pumpApp(tester);
    await tap(tester, 'home-progress');

    expect(find.byKey(ValueKey('cal-check-$today')), findsOneWidget);
    expect(find.byKey(ValueKey('cal-dot-$today')), findsNothing);
    expect(find.byKey(ValueKey('cal-check-$other')), findsNothing);
    expect(find.text('오늘의 단어 완료'), findsOneWidget);
  });
}
