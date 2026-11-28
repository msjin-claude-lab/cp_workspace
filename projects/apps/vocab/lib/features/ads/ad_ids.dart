import 'package:flutter/foundation.dart';

// AdMob 배너 광고 단위 ID(2026-11-29 사용자 결정 — debug는 Google 테스트 ID, release는 실제 ID).
// 앱 ID는 android/app/build.gradle.kts의 manifestPlaceholders["admobAppId"].
// 실제 ID는 저장소에서 이 한 곳에만 적는다. release를 기기에 깔았을 때 광고를 누르지 않는다(부정 클릭).

/// Google 공식 테스트 배너 단위(https://developers.google.com/admob/android/test-ads).
const testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

/// 실제 배너 단위 `vocara_list_banner`.
const releaseBannerAdUnitId = 'ca-app-pub-5860744543403858/2609798451';

/// 지금 빌드가 쓰는 배너 단위(release만 실제 ID).
const bannerAdUnitId = kReleaseMode
    ? releaseBannerAdUnitId
    : testBannerAdUnitId;
