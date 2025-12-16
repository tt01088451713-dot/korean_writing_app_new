// lib/screens/app_info_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:korean_writing_app_new/ads/ads_purchase_state.dart';
import 'package:korean_writing_app_new/i18n/ui_texts.dart';

class AppInfoPage extends StatelessWidget {
  const AppInfoPage({super.key});

  // i18n + 안전 폴백
  String _t(String key, String fallback) {
    try {
      final s = UiText.t(key);
      if (s.trim().isNotEmpty && s != key) return s;
    } catch (_) {}
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 Provider로 등록된 AdsPurchaseState 사용
    final adsState = context.watch<AdsPurchaseState>();

    // 아직 로드 안 됐으면 한 번만 ensureLoaded() 호출
    if (!adsState.isInitialized) {
      // build 안에서 바로 await는 못 하니 microtask로 넘겨 실행
      Future.microtask(() => adsState.ensureLoaded());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('appInfo.title', 'About This App')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ───────── App Title ─────────
              Text(
                _t('appTitle', 'Korean Writing App'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // ───────── Developer & Author Info ─────────
              const Text(
                'Developed by KST Lingua Studio',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4),
              const Text(
                'Educational contents designed by Prof. Sang-Tae Kim (Cheongju University)',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 6),
              const Text(
                'Contact: support-kst@naver.com',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4),
              const Text(
                'Version 1.0.0 (2025)',
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 24),

              // ───────── App Description ─────────
              Text(
                _t('appInfo.aboutSectionTitle', 'About:'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'This app helps learners of Korean practice writing and pronunciation '
                    'through structured lessons, stroke-by-stroke handwriting, and audio playback. '
                    'It supports multiple languages for multicultural learners around the world.',
                style: TextStyle(fontSize: 15, height: 1.4),
              ),

              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 16),

              // ───────── Ads / Remove Ads 섹션 ─────────
              Text(
                _t('appInfo.adsSectionTitle', 'Ads & Remove Ads'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              if (!adsState.isInitialized)
              // SharedPreferences + IAP 초기화 대기
                Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _t(
                        'appInfo.loadingPurchase',
                        'Loading purchase information...',
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                )
              else
                Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    child: Column(
                      children: [
                        // ───── Remove Ads 구매 ─────
                        ListTile(
                          title: Text(
                            _t('appInfo.removeAdsTitle', 'Remove Ads'),
                          ),
                          subtitle: Text(
                            adsState.isAdsRemoved
                                ? _t(
                              'appInfo.removeAdsPurchased',
                              'Ads are removed on this device.',
                            )
                                : _t(
                              'appInfo.removeAdsNotPurchased',
                              'Remove all banner and rewarded ads permanently.',
                            ),
                          ),
                          trailing: ElevatedButton(
                            onPressed: (adsState.isAdsRemoved ||
                                adsState.isProcessing)
                                ? null
                                : () async {
                              await adsState.buyRemoveAds();
                            },
                            child: adsState.isProcessing
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                                : Text(
                              adsState.isAdsRemoved
                                  ? _t(
                                'appInfo.removeAdsButtonDone',
                                'Purchased',
                              )
                                  : _t(
                                'appInfo.removeAdsButtonBuy',
                                'Buy',
                              ),
                            ),
                          ),
                        ),

                        const Divider(),

                        // ───── Restore Purchases ─────
                        ListTile(
                          title: Text(
                            _t('appInfo.restoreTitle', 'Restore Purchases'),
                          ),
                          subtitle: Text(
                            _t(
                              'appInfo.restoreSubtitle',
                              'If you have already purchased Remove Ads on this account/device,\n'
                                  'you can restore it here.',
                            ),
                          ),
                          trailing: OutlinedButton(
                            onPressed: adsState.isProcessing
                                ? null
                                : () async {
                              await adsState.restorePurchases();
                            },
                            child: Text(
                              _t('appInfo.restoreButton', 'Restore'),
                            ),
                          ),
                        ),

                        // ───── 디버그용 토글 (디버그 빌드에서만 표시) ─────
                        if (kDebugMode) ...[
                          const SizedBox(height: 8),
                          const Divider(),
                          SwitchListTile(
                            title: Text(
                              _t(
                                'appInfo.debugRemoveAdsToggle',
                                'Test: Remove Ads state (development only)',
                              ),
                            ),
                            subtitle: Text(
                              adsState.isAdsRemoved
                                  ? _t(
                                'appInfo.debugRemoveAdsOn',
                                'Current status: Ads are removed.',
                              )
                                  : _t(
                                'appInfo.debugRemoveAdsOff',
                                'Current status: Ads are shown.',
                              ),
                            ),
                            value: adsState.isAdsRemoved,
                            onChanged: (value) async {
                              if (value) {
                                await adsState.markAdsRemoved();
                              } else {
                                await adsState.resetAdsRemovedForDebug();
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 10),

              // ───────── Copyright ─────────
              const Center(
                child: Text(
                  '© 2025 KST Lingua Studio & Prof. Sang-Tae Kim. All rights reserved.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
