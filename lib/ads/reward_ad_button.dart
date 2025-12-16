// lib/ads/reward_ad_button.dart
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import 'package:korean_writing_app_new/ads/ads_purchase_state.dart';
import 'package:korean_writing_app_new/services/admob_service.dart';

/// 보상형 광고를 보여주는 버튼 위젯.
/// 예: "힌트 더 받기", "연습 기회 +1" 등에 사용 가능.
class RewardAdButton extends StatefulWidget {
  /// 광고를 끝까지 본 후에 실제 보상을 처리하는 콜백.
  /// 예: onRewardEarned: () { hintCount++; }
  final VoidCallback onRewardEarned;

  /// 버튼에 표시할 텍스트
  final String label;

  const RewardAdButton({
    super.key,
    required this.onRewardEarned,
    this.label = 'Watch Ad for Reward',
  });

  @override
  State<RewardAdButton> createState() => _RewardAdButtonState();
}

class _RewardAdButtonState extends State<RewardAdButton> {
  bool _isShowingAd = false;

  Future<void> _handlePressed() async {
    if (_isShowingAd) return;

    setState(() {
      _isShowingAd = true;
    });

    final admob = AdmobService.instance;

    final hasShown = await admob.showRewardedAd(
      onUserEarnedReward: (RewardItem reward) {
        // ✅ 실제 보상 처리
        widget.onRewardEarned();
      },
    );

    if (!mounted) return;

    if (!hasShown) {
      // 광고가 아직 준비되지 않았을 경우 사용자에게 안내 (선택)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ad is not ready yet. Please try again soon.'),
        ),
      );
    }

    setState(() {
      _isShowingAd = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 새 전역 상태(AdsPurchaseState)에서 광고 제거 여부 확인
    final isAdsRemoved =
    context.select<AdsPurchaseState, bool>((s) => s.isAdsRemoved);

    // 광고 제거를 구매한 경우: 버튼 아예 숨김
    if (isAdsRemoved) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: _isShowingAd ? null : _handlePressed,
        child: _isShowingAd
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : Text(widget.label),
      ),
    );
  }
}
