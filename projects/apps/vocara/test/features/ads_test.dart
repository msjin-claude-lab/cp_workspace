import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vocara/data/app_settings.dart';
import 'package:vocara/data/cell.dart';
import 'package:vocara/data/cell_store.dart';
import 'package:vocara/data/reminder_settings.dart';
import 'package:vocara/data/speaker.dart';
import 'package:vocara/data/study_decks.dart';
import 'package:vocara/data/study_records.dart';
import 'package:vocara/data/word_repository.dart';
import 'package:vocara/features/ads/ad_ids.dart';
import 'package:vocara/features/about/about_screen.dart';
import 'package:vocara/features/ads/banner_ad.dart';
import 'package:vocara/features/home/home_screen.dart';
import 'package:vocara/features/progress/progress_screen.dart';
import 'package:vocara/features/quiz/quiz.dart' show quizRandomProvider;
import 'package:vocara/features/quiz/quiz_screen.dart';
import 'package:vocara/features/reminder/reminder_notifications.dart';
import 'package:vocara/features/settings/settings_screen.dart';
import 'package:vocara/features/study/study_screen.dart';
import 'package:vocara/features/wrong_notes/wrong_notes_screen.dart';
import 'package:vocara/router.dart';

import '../fakes.dart';

void main() {
  late FakeRecords records;
  late FakeStudyDecks decks;
  late StudyDeck deck;
  late GoRouter router;

  final words = {
    Cell.elementaryEasy: [
      for (var i = 0; i < 6; i++) fakeWord('ee-00$i', 'e$i', '뜻$i'),
    ],
  };

  setUp(() {
    records = FakeRecords();
    decks = FakeStudyDecks(records);
    deck = decks.seed('아침 단어', Cell.elementaryEasy);
    router = createRouter();
  });

  Future<void> pumpApp(WidgetTester tester, FakeBannerAds ads) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bannerAdsProvider.overrideWithValue(ads),
          legacySettingsStoreProvider.overrideWithValue(
            FakeLegacySettingsStore(),
          ),
          wordRepositoryProvider.overrideWithValue(FakeRepository(words)),
          cellStoreProvider.overrideWithValue(
            FakeCellStore(selectedDeck: deck.deckId),
          ),
          studyDecksProvider.overrideWithValue(decks),
          studyRecordsProvider.overrideWithValue(records),
          speakerProvider.overrideWithValue(FakeSpeaker()),
          quizRandomProvider.overrideWithValue(NoShuffleRandom()),
          reminderSettingsStoreProvider.overrideWithValue(
            FakeReminderSettingsStore(),
          ),
          reminderNotificationsProvider.overrideWithValue(
            FakeReminderNotifications(),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> go(WidgetTester tester, String path) async {
    router.go(path);
    await tester.pumpAndSettle();
  }

  testWidgets('배너 자리는 홈·새 단어장 만들기·오답 노트·진도·설정에 있고, 카드 학습·오늘의 단어·시험·앱 정보에는 없다', (
    tester,
  ) async {
    await pumpApp(tester, FakeBannerAds(loaded: true));
    final id = deck.id;

    // 경로 → 그 경로에서 보여야 할 화면(엉뚱한 화면에서 "없음"을 확인하지 않게)
    final withBanner = {
      '/': DeckHomeScreen,
      // 새 단어장 만들기 흐름(2026-11-29 사용자 결정)
      '/pick?name=new': LevelPickerScreen,
      '/pick/elementary?name=new': DifficultyPickerScreen,
      '/wrong-notes/$id': WrongNotesScreen,
      '/progress/$id': ProgressScreen,
      '/settings/$id': SettingsScreen,
    };
    final withoutBanner = {
      '/study/$id': StudyScreen,
      '/today/$id': StudyScreen,
      '/quiz/$id': QuizScreen,
      '/review/quiz/$id': QuizScreen, // 오답 시험(2026-11-29 검토 지적)
      '/about': AboutScreen,
    };
    for (final MapEntry(key: path, value: screen) in withBanner.entries) {
      await go(tester, path);
      expect(find.byType(screen), findsOneWidget, reason: path);
      expect(find.byType(BottomBanner), findsOneWidget, reason: path);
      expect(find.byKey(const ValueKey('fake-banner')), findsOneWidget);
    }
    for (final MapEntry(key: path, value: screen) in withoutBanner.entries) {
      await go(tester, path);
      expect(find.byType(screen), findsOneWidget, reason: path);
      expect(find.byType(BottomBanner), findsNothing, reason: path);
      expect(find.byKey(const ValueKey('fake-banner')), findsNothing);
      if (screen == StudyScreen) {
        final today = tester.widget<StudyScreen>(find.byType(StudyScreen));
        expect(today.today, path.startsWith('/today'), reason: path);
      }
    }
  });

  testWidgets('단어장이 하나도 없을 때의 시작 화면에도 배너가 있다(2026-11-29 사용자 결정)', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [bannerAdsProvider.overrideWithValue(FakeBannerAds(loaded: true))],
        child: const MaterialApp(home: StartScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(BottomBanner), findsOneWidget);
    expect(find.byKey(const ValueKey('fake-banner')), findsOneWidget);
  });

  testWidgets('광고를 불러오지 못하면(실패·오프라인) 배너 자리는 높이 0이고 화면은 그대로다', (tester) async {
    final ads = FakeBannerAds();
    await pumpApp(tester, ads);

    expect(ads.loads, 1);
    expect(tester.getSize(find.byType(BottomBanner)).height, 0);
    expect(find.byKey(const ValueKey('fake-banner')), findsNothing);
    expect(find.byKey(const ValueKey('home-register')), findsOneWidget);
  });

  testWidgets('광고를 불러오면 화면 맨 아래에 보이고 "새 등록" 버튼과 겹치지 않는다', (tester) async {
    await pumpApp(tester, FakeBannerAds(loaded: true));

    final banner = tester.getRect(find.byKey(const ValueKey('fake-banner')));
    final fab = tester.getRect(find.byKey(const ValueKey('home-register')));
    expect(banner.size, const Size(320, 50));
    expect(banner.bottom, 1600); // 화면 맨 아래
    expect(fab.bottom, lessThanOrEqualTo(banner.top)); // 버튼은 배너 위
    expect(fab.overlaps(banner), isFalse);
  });

  testWidgets('배너 자리가 사라지면 불러온 광고를 정리한다', (tester) async {
    final ads = FakeBannerAds(loaded: true);
    await pumpApp(tester, ads);
    expect(ads.released, 0);

    await go(tester, '/study/${deck.id}');
    expect(ads.released, ads.loads);
  });

  test('모든 광고 요청은 어린이 대상·최대 등급 G로 설정한다', () {
    final config = childDirectedRequestConfiguration();
    expect(config.ageRestrictedTreatment, AgeRestrictedTreatment.child);
    expect(
      // ignore: deprecated_member_use
      config.tagForChildDirectedTreatment,
      // ignore: deprecated_member_use
      TagForChildDirectedTreatment.yes,
    );
    expect(config.maxAdContentRating, MaxAdContentRating.g);
  });

  test('debug·시험 빌드는 Google 테스트 배너 단위를 쓴다', () {
    expect(bannerAdUnitId, testBannerAdUnitId);
    expect(testBannerAdUnitId, 'ca-app-pub-3940256099942544/6300978111');
  });

  test('광고의 기본값은 광고 없음이다 — 앱 시작에서 성공했을 때만 AdMob으로 바꾼다(검토 LOW 7)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(bannerAdsProvider), isA<NoBannerAds>());
  });
}
