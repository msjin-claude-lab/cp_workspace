import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vocab/data/app_settings.dart';
import 'package:vocab/data/cell.dart';
import 'package:vocab/data/cell_store.dart';
import 'package:vocab/data/reminder_settings.dart';
import 'package:vocab/data/speaker.dart';
import 'package:vocab/data/study_decks.dart';
import 'package:vocab/data/study_records.dart';
import 'package:vocab/data/word_repository.dart';
import 'package:vocab/features/reminder/reminder_controller.dart';
import 'package:vocab/features/reminder/reminder_host.dart';
import 'package:vocab/features/reminder/reminder_notifications.dart';
import 'package:vocab/features/reminder/reminder_schedule.dart';
import 'package:vocab/features/study/study_screen.dart';
import 'package:vocab/router.dart';

import '../fakes.dart';

/// 매일 알림(2026-11-28 사용자 결정): 처음 실행 때 권한, 안 끝낸 날만 정한 시각에, 누르면 오늘의 단어.
void main() {
  group('다음 알림 시각', () {
    test('안 끝냈고 시각 전이면 오늘 그 시각', () {
      expect(
        nextReminderTime(
          DateTime(2026, 11, 28, 18, 59),
          hour: 19,
          minute: 0,
          completedToday: false,
        ),
        DateTime(2026, 11, 28, 19),
      );
    });

    test('시각이 지났거나(같은 순간 포함) 오늘 끝냈으면 내일 그 시각', () {
      for (final (now, done) in [
        (DateTime(2026, 11, 28, 19), false),
        (DateTime(2026, 11, 28, 21, 30), false),
        (DateTime(2026, 11, 28, 8), true),
      ]) {
        expect(
          nextReminderTime(now, hour: 19, minute: 0, completedToday: done),
          DateTime(2026, 11, 29, 19),
        );
      }
    });

    test('달·해가 바뀌는 날도 다음 날로 넘어간다', () {
      expect(
        nextReminderTime(
          DateTime(2026, 12, 31, 23),
          hour: 7,
          minute: 30,
          completedToday: true,
        ),
        DateTime(2027, 1, 1, 7, 30),
      );
    });

    test('문구에 개수가 들어간다', () {
      expect(reminderBody(10), '오늘의 단어 10개가 기다려요');
    });
  });

  late FakeReminderSettingsStore store;
  late FakeReminderNotifications notifications;
  late FakeStudyDecks decks;
  late FakeRecords records;
  late StudyDeck deck;
  var now = DateTime(2026, 11, 28, 9);

  setUp(() {
    store = FakeReminderSettingsStore();
    notifications = FakeReminderNotifications();
    records = FakeRecords();
    decks = FakeStudyDecks(records);
    deck = decks.seed('아침 단어', Cell.elementaryEasy);
    now = DateTime(2026, 11, 28, 9);
  });

  List<Override> overrides() => [
    noBannerAds(),
    reminderSettingsStoreProvider.overrideWithValue(store),
    reminderNotificationsProvider.overrideWithValue(notifications),
    studyDecksProvider.overrideWithValue(decks),
    studyRecordsProvider.overrideWithValue(records),
    cellStoreProvider.overrideWithValue(
      FakeCellStore(selectedDeck: deck.deckId),
    ),
    nowProvider.overrideWithValue(() => now),
    legacySettingsStoreProvider.overrideWithValue(FakeLegacySettingsStore()),
    wordRepositoryProvider.overrideWithValue(
      FakeRepository({
        Cell.elementaryEasy: [
          for (var i = 0; i < 3; i++) fakeWord('ee-$i', 'w$i', '뜻$i'),
        ],
      }),
    ),
    speakerProvider.overrideWithValue(FakeSpeaker()),
  ];

  ProviderContainer container() {
    final c = ProviderContainer(overrides: overrides());
    addTearDown(c.dispose);
    return c;
  }

  group('처음 실행 때 권한', () {
    test('허용하면 알림이 켜지고(20:00) 저장되며, 오늘 20시부터 지금 단어장으로 예약된다', () async {
      final c = container();
      final controller = c.read(reminderControllerProvider.notifier);
      await controller.askOnFirstLaunch();
      await controller.reschedule();

      expect(notifications.requests, 1);
      expect(store.asked, isTrue);
      expect(
        store.settings,
        const ReminderSettings(enabled: true, hour: 20, minute: 0),
      );
      expect(c.read(reminderControllerProvider).value!.enabled, isTrue);
      expect(notifications.scheduled!.first, DateTime(2026, 11, 28, 20));
      expect(notifications.scheduled!.body, '오늘의 단어 10개가 기다려요');
      expect(notifications.scheduled!.payload, deck.id);
    });

    test('거절하면 꺼진 채로 저장되고 예약하지 않는다', () async {
      notifications.grant = false;
      final c = container();
      final controller = c.read(reminderControllerProvider.notifier);
      await controller.askOnFirstLaunch();
      await controller.reschedule();

      expect(notifications.requests, 1);
      expect(store.asked, isTrue);
      expect(store.settings.enabled, isFalse);
      expect(notifications.scheduled, isNull);
    });

    test('한 번 물었으면(앱을 다시 시작해도) 다시 묻지 않고 설정도 그대로다', () async {
      store
        ..asked = true
        ..settings = const ReminderSettings(enabled: true, hour: 7, minute: 5);
      final c = container();
      await c.read(reminderControllerProvider.notifier).askOnFirstLaunch();
      expect(notifications.requests, 0);
      expect(store.settings.hour, 7);

      // 첫 실행에서 물은 뒤 다시 실행
      final fresh = FakeReminderSettingsStore();
      store = fresh;
      final c2 = container();
      await c2.read(reminderControllerProvider.notifier).askOnFirstLaunch();
      final c3 = container();
      await c3.read(reminderControllerProvider.notifier).askOnFirstLaunch();
      expect(notifications.requests, 1);
    });
  });

  group('설정과 예약', () {
    test('켤 때 권한이 없으면 다시 묻고, 거절되면 켜지지 않는다(false)', () async {
      notifications.grant = false;
      final c = container();
      await c.read(reminderControllerProvider.future);
      final ok = await c
          .read(reminderControllerProvider.notifier)
          .setEnabled(true);
      expect(ok, isFalse);
      expect(notifications.requests, 1);
      expect(store.settings.enabled, isFalse);
      expect(notifications.scheduled, isNull);
    });

    test('켜고 시각을 바꾸면 예약이 바뀌고, 끄면 예약이 지워진다', () async {
      notifications.permitted = true;
      final c = container();
      final controller = c.read(reminderControllerProvider.notifier);
      await c.read(reminderControllerProvider.future);
      expect(await controller.setEnabled(true), isTrue);
      expect(notifications.requests, 0); // 이미 허용돼 있으면 묻지 않는다
      expect(notifications.scheduled!.first, DateTime(2026, 11, 28, 20));

      await controller.setTime(8, 30); // 이미 지난 시각 → 내일
      expect(
        store.settings,
        const ReminderSettings(enabled: true, hour: 8, minute: 30),
      );
      expect(notifications.scheduled!.first, DateTime(2026, 11, 29, 8, 30));

      await controller.setEnabled(false);
      expect(notifications.scheduled, isNull);
    });

    test('오늘의 단어를 끝낸 날은 오늘 알림이 빠지고 내일부터 예약된다(문구 개수는 오늘 고른 수)', () async {
      store.settings = const ReminderSettings(enabled: true);
      decks.dailySets[(deck.deckId, '2026-11-28')] = const DailySet(
        day: '2026-11-28',
        wordIds: ['ee-0', 'ee-1'],
        seenIds: {'ee-0'},
      );
      final c = container();
      final controller = c.read(reminderControllerProvider.notifier);
      await controller.reschedule();
      expect(notifications.scheduled!.first, DateTime(2026, 11, 28, 20));
      expect(notifications.scheduled!.body, '오늘의 단어 2개가 기다려요');

      decks.dailySets[(deck.deckId, '2026-11-28')] = const DailySet(
        day: '2026-11-28',
        wordIds: ['ee-0', 'ee-1'],
        seenIds: {'ee-0', 'ee-1'},
      );
      await controller.reschedule();
      expect(notifications.scheduled!.first, DateTime(2026, 11, 29, 20));
      // 내일 알림이므로 오늘 묶음(2개)이 아니라 저장된 개수(기본 10)로 알린다
      expect(notifications.scheduled!.body, '오늘의 단어 10개가 기다려요');
    });

    test('문구의 개수는 오늘 고르기 전이면 그 단어장의 설정값', () async {
      store.settings = const ReminderSettings(enabled: true);
      decks.dailyCounts[deck.deckId] = 15;
      final c = container();
      await c.read(reminderControllerProvider.notifier).reschedule();
      expect(notifications.scheduled!.body, '오늘의 단어 15개가 기다려요');
    });
  });

  group('앱을 감싼 알림 돌보기', () {
    Future<GoRouter> pumpHost(WidgetTester tester) async {
      final router = createRouter();
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(),
          child: MaterialApp.router(
            routerConfig: router,
            builder: (context, child) =>
                ReminderHost(router: router, child: child!),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('처음 실행하면 권한을 한 번 묻고, 알림으로 시작했으면 오늘의 단어 화면을 연다', (tester) async {
      notifications.launch = deck.id;
      await pumpHost(tester);
      expect(notifications.requests, 1);
      expect(store.asked, isTrue);
      expect(notifications.onTap, isNotNull);
      final screen = tester.widget<StudyScreen>(find.byType(StudyScreen));
      expect(screen.today, isTrue);
      expect(find.text('아침 단어 - 오늘의 단어'), findsOneWidget);
    });

    testWidgets('앱이 떠 있을 때 알림을 누르면 오늘의 단어 화면을 연다', (tester) async {
      store.asked = true;
      await pumpHost(tester);
      expect(notifications.requests, 0);
      expect(find.byType(StudyScreen), findsNothing);

      notifications.onTap!(deck.id);
      await tester.pumpAndSettle();
      expect(find.text('아침 단어 - 오늘의 단어'), findsOneWidget);
    });
  });
}
