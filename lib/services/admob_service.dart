// lib/services/admob_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 앱 전체에서 사용하는 AdMob 서비스.
/// - 초기화
/// - 보상형 광고 로딩 / 표시 관리
class AdmobService {
  AdmobService._internal();
  static final AdmobService instance = AdmobService._internal();

  bool _isInitialized = false;

  /// 보상형 광고 관련 필드
  RewardedAd? _rewardedAd;
  bool _isLoadingRewardedAd = false;

  /// 외부에서 상태를 가볍게 확인하고 싶을 때 사용 (선택)
  bool get isInitialized => _isInitialized;
  bool get isLoadingRewardedAd => _isLoadingRewardedAd;
  bool get hasRewardedAdLoaded => _rewardedAd != null;

  /// 실제 광고 단위 ID: 플랫폼에 따라 다르게 반환
  /// 디버그 모드에서는 Google 공식 테스트 ID 사용
  String get bannerAdUnitId {
    if (kDebugMode) {
      // 테스트용 배너 광고 ID
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
    } else {
      // 🔹 실제 배너 광고 ID
      if (Platform.isAndroid) {
        // Android 배너
        return 'ca-app-pub-3746752589798871/1456633035';
      } else if (Platform.isIOS) {
        // TODO: iOS 배너 ID 생성 후 아래 값 교체
        return 'ca-app-pub-3746752589798871/IOS_BANNER_ID';
      }
      return '';
    }
  }

  String get rewardedAdUnitId {
    if (kDebugMode) {
      // 테스트용 보상형 광고 ID
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';
    } else {
      // 🔹 실제 보상형 광고 ID
      if (Platform.isAndroid) {
        // Android 보상형
        return 'ca-app-pub-3746752589798871/6294026741';
      } else if (Platform.isIOS) {
        // TODO: iOS 보상형 ID 생성 후 아래 값 교체
        return 'ca-app-pub-3746752589798871/IOS_REWARDED_ID';
      }
      return '';
    }
  }

  /// 반드시 앱 시작 시 한 번 호출
  /// (호출하지 않아도 showRewardedAd에서 로딩을 시도하지만,
  ///  사전 로딩을 위해 initialize()를 권장)
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 필요 시 테스트 디바이스 ID를 지정할 수 있음
    final requestConfiguration = RequestConfiguration(
      testDeviceIds: const <String>[],
    );
    MobileAds.instance.updateRequestConfiguration(requestConfiguration);

    await MobileAds.instance.initialize();
    _isInitialized = true;

    // 초기 보상형 광고 로딩
    await loadRewardedAd();
  }

  /// 보상형 광고 로딩
  Future<void> loadRewardedAd() async {
    if (!_isInitialized) return;
    if (_isLoadingRewardedAd) return;
    if (_rewardedAd != null) return;

    final adUnitId = rewardedAdUnitId;
    if (adUnitId.isEmpty) {
      debugPrint('RewardedAd unit id is empty for this platform.');
      return;
    }

    _isLoadingRewardedAd = true;

    await RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _isLoadingRewardedAd = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('RewardedAd failed to load: $error');
          _isLoadingRewardedAd = false;
          _rewardedAd = null;
        },
      ),
    );
  }

  /// 보상형 광고 표시
  ///
  /// [onUserEarnedReward] : 유저가 광고를 끝까지 보았을 때 호출
  /// 반환값: 실제로 광고를 보여줬으면 true, 아니면 false
  Future<bool> showRewardedAd({
    required void Function(RewardItem reward) onUserEarnedReward,
  }) async {
    if (!_isInitialized) {
      debugPrint('AdmobService not initialized');
      return false;
    }

    final ad = _rewardedAd;
    if (ad == null) {
      // 아직 로딩이 안 되었으면 일단 다시 로딩 요청
      await loadRewardedAd();
      debugPrint('RewardedAd not ready yet');
      return false;
    }

    _rewardedAd = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('RewardedAd onAdShowedFullScreenContent');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('RewardedAd onAdDismissedFullScreenContent');
        ad.dispose();
        // 다시 다음 광고 미리 로딩
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('RewardedAd failed to show: $error');
        ad.dispose();
        loadRewardedAd();
      },
    );

    await ad.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        onUserEarnedReward(reward);
      },
    );

    return true;
  }

  /// 앱 종료 시 정리용 (필수는 아님)
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
