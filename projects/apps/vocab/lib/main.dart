import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app_info.dart';
import 'features/ads/banner_ad.dart';
import 'features/reminder/reminder_host.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 광고(2026-11-29): 어린이 대상 설정을 광고 요청보다 먼저 적용한다. 적용하지 못하면 광고 없이 연다
  final adsReady = await startAds();
  runApp(
    ProviderScope(
      overrides: [
        if (!adsReady) bannerAdsProvider.overrideWithValue(const NoBannerAds()),
      ],
      child: const VocabApp(),
    ),
  );
}

class VocabApp extends StatelessWidget {
  const VocabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: appTitle,
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.indigo)),
      routerConfig: appRouter,
      // 매일 알림: 처음 실행 때 권한 묻기, 예약, 알림을 누르면 오늘의 단어(2026-11-28 사용자 결정)
      builder: (context, child) =>
          ReminderHost(router: appRouter, child: child ?? const SizedBox()),
    );
  }
}
