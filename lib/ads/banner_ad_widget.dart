// lib/ads/banner_ad_widget.dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import 'package:korean_writing_app_new/i18n/ui_texts.dart';
import 'package:korean_writing_app_new/i18n/language_state.dart';
import 'package:korean_writing_app_new/ads/ads_purchase_state.dart';

/// 하단에 붙는 배너 광고 영역.
class BannerAdArea extends StatefulWidget {
  const BannerAdArea({super.key});

  @override
  State<BannerAdArea> createState() => _BannerAdAreaState();
}

class _BannerAdAreaState extends State<BannerAdArea> {
  BannerAd? _banner;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _initBanner();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  /// 플랫폼별 배너 ID
  String _bannerUnitId() {
    // 🔹 디버그일 때: Google 제공 테스트 배너
    if (kDebugMode) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return 'ca-app-pub-3940256099942544/6300978111';
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return 'ca-app-pub-3940256099942544/2934735716';
      }
      return '';
    }

    // 🔹 릴리스(실제 배포용): 교수님 실제 배너 ID 입력
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ca-app-pub-3746752589798871/1456633035';
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ca-app-pub-3746752589798871/IOS_BANNER_ID'; // iOS 생성 후 교체
    }

    return '';
  }

  void _initBanner() {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final unitId = _bannerUnitId();
    if (unitId.isEmpty) return;

    final ad = BannerAd(
      size: AdSize.banner,
      adUnitId: unitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() {
            _banner = ad as BannerAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );

    ad.load();
  }

  String _placeholderText() {
    const key = 'ads.bannerPlaceholder';
    final fromUi = UiText.t(key);
    if (fromUi != key && fromUi.trim().isNotEmpty) return fromUi;

    final code = LanguageState.I.code.split('-').first;
    if (code == 'en') {
      return 'An educational banner ad will appear here.\n'
          'This area disappears when you purchase Remove Ads.';
    }
    return '여기에 학습용 배너 광고가 표시됩니다.\n'
        '광고 제거(Remove Ads)를 구매하면 보이지 않습니다.';
  }

  @override
  Widget build(BuildContext context) {
    final adsState = context.watch<AdsPurchaseState>();

    // 🔹 광고 제거 구매한 경우: 아무것도 표시하지 않음
    if (adsState.isAdsRemoved) {
      return const SizedBox.shrink();
    }

    // 🔹 플랫폼 미지원 → 안내 문구
    if (!Platform.isAndroid && !Platform.isIOS) {
      return _PlaceholderBar(text: _placeholderText());
    }

    // 🔹 로딩 실패 → 안내 문구
    if (!_isLoaded || _banner == null) {
      return _PlaceholderBar(text: _placeholderText());
    }

    return Container(
      alignment: Alignment.center,
      width: _banner!.size.width.toDouble(),
      height: _banner!.size.height.toDouble(),
      child: AdWidget(ad: _banner!),
    );
  }
}

class _PlaceholderBar extends StatelessWidget {
  final String text;
  const _PlaceholderBar({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      color: Colors.grey.shade100,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11, color: Colors.black54),
      ),
    );
  }
}
