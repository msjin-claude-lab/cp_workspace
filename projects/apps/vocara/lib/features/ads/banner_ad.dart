import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:material_ui/material_ui.dart';

import 'ad_ids.dart';

// 광고(2026-11-29 사용자 결정): AdMob 배너만, 모든 사용자를 어린이 대상으로(child-directed·등급 G).
// 홈·오답 노트·진도·설정 화면과, 단어장이 없을 때의 시작 화면·새 단어장 만들기(학교급·난이도 고르기) 아래에
// [BottomBanner]를 둔다(2026-11-29 사용자 결정). 공부 화면(카드·오늘의 단어·시험·오답 시험)과 앱 정보에는 없다.
// 불러오기에 성공한 뒤에만 자리가 생기고, 실패·오프라인이면 자리가 없다.
// 광고 SDK는 [BannerAds] 뒤에 둔다 — 시험에서는 가짜를 넣는다(플랫폼 채널을 쓰지 않는다).

/// 모든 광고 요청에 붙는 설정: 어린이 대상, 최대 광고 콘텐츠 등급 G.
/// `tagForChildDirectedTreatment`는 9.x에서 `ageRestrictedTreatment`로 바뀌는 중이라 둘 다 넣는다
/// (https://developers.google.com/admob/flutter/targeting).
RequestConfiguration childDirectedRequestConfiguration() =>
    RequestConfiguration(
      ageRestrictedTreatment: AgeRestrictedTreatment.child,
      // ignore: deprecated_member_use
      tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
      maxAdContentRating: MaxAdContentRating.g,
    );

/// 앱 시작 때 한 번 부른다. 어린이 대상 설정을 먼저 적용하고 그다음 SDK를 초기화한다.
/// 설정을 적용하지 못하면 false — 그때는 광고를 요청하지 않는다(main.dart가 [NoBannerAds]로 바꾼다).
/// 초기화는 기다리지 않는다(오프라인이어도 앱이 바로 뜬다).
Future<bool> startAds() async {
  // 광고는 Android만. iOS는 Info.plist에 앱 ID(GADApplicationIdentifier)가 없어 initialize가 앱을 끝낸다
  // (iOS 보류 중 — 다시 시작할 때 앱 ID·SKAdNetworkItems를 넣고 이 줄을 고친다).
  if (defaultTargetPlatform != TargetPlatform.android) return false;
  try {
    await MobileAds.instance.updateRequestConfiguration(
      childDirectedRequestConfiguration(),
    );
  } catch (_) {
    return false;
  }
  MobileAds.instance.initialize().ignore();
  return true;
}

/// 불러온 배너: 보여 줄 위젯과 크기.
class LoadedBanner {
  const LoadedBanner({required this.view, required this.size});

  final Widget view;
  final Size size;
}

/// 배너 광고를 불러오는 곳.
abstract interface class BannerAds {
  /// 배너 하나를 불러오기 시작한다. 성공하면 [onLoaded]를 부르고, 실패하면 아무것도 부르지 않는다.
  /// 돌려준 함수는 배너 자리가 사라질 때 부른다(불러오는 중이면 그만두고, 불러온 것이면 정리한다).
  VoidCallback load(void Function(LoadedBanner banner) onLoaded);
}

/// 광고 없음 — 늘 자리가 없다.
class NoBannerAds implements BannerAds {
  const NoBannerAds();

  @override
  VoidCallback load(void Function(LoadedBanner banner) onLoaded) => () {};
}

/// AdMob 배너(고정 크기 320×50).
class AdMobBannerAds implements BannerAds {
  const AdMobBannerAds();

  @override
  VoidCallback load(void Function(LoadedBanner banner) onLoaded) {
    var disposed = false;
    void dispose(Ad ad) {
      if (disposed) return;
      disposed = true;
      ad.dispose();
    }

    late final BannerAd ad;
    ad = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (disposed) return;
          onLoaded(
            LoadedBanner(
              view: AdWidget(ad: ad),
              size: Size(ad.size.width.toDouble(), ad.size.height.toDouble()),
            ),
          );
        },
        onAdFailedToLoad: (failed, _) => dispose(failed),
      ),
    );
    unawaited(ad.load().catchError((_) => dispose(ad)));
    return () => dispose(ad);
  }
}

/// 기본값은 광고 없음 — 앱 시작(`main.dart`)에서 [startAds]가 성공했을 때만 [AdMobBannerAds]로 바꾼다.
/// 시험에서 가짜를 넣지 않아도 플랫폼 채널을 부르지 않는다(2026-11-29 검토 LOW 7).
final bannerAdsProvider = Provider<BannerAds>((ref) => const NoBannerAds());

/// 화면 아래 배너 자리. `Scaffold.bottomNavigationBar`에 넣는다 — Scaffold가 "새 등록" 같은
/// 떠 있는 버튼을 이 자리 위로 올리므로 겹치지 않는다. 불러오기 전·실패면 높이 0.
class BottomBanner extends ConsumerStatefulWidget {
  const BottomBanner({super.key = const ValueKey('bottom-banner')});

  @override
  ConsumerState<BottomBanner> createState() => _BottomBannerState();
}

class _BottomBannerState extends ConsumerState<BottomBanner> {
  LoadedBanner? _banner;
  late final VoidCallback _release;

  @override
  void initState() {
    super.initState();
    _release = ref.read(bannerAdsProvider).load((banner) {
      if (mounted) setState(() => _banner = banner);
    });
  }

  @override
  void dispose() {
    _release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    if (banner == null) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: SizedBox(
        height: banner.size.height,
        child: Center(
          child: SizedBox.fromSize(size: banner.size, child: banner.view),
        ),
      ),
    );
  }
}
