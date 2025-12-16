// lib/purchase_state.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseState extends ChangeNotifier {
  static const String _kHasRemovedAdsKey = 'has_removed_ads';

  bool _hasRemovedAds = false;
  bool _initialized = false;

  bool get hasRemovedAds => _hasRemovedAds;
  bool get initialized => _initialized;

  /// 앱 시작 시 호출: 광고 제거 여부 불러오기
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasRemovedAds = prefs.getBool(_kHasRemovedAdsKey) ?? false;
    } catch (e) {
      debugPrint('PurchaseState.load error: $e');
      _hasRemovedAds = false; // 안전 기본값
    }

    _initialized = true;
    notifyListeners();
  }

  /// 광고 제거 상태 업데이트 + 저장
  Future<void> setRemovedAds(bool value) async {
    _hasRemovedAds = value;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kHasRemovedAdsKey, value);
    } catch (e) {
      debugPrint('PurchaseState.setRemovedAds error: $e');
      // 저장 실패 시에도 앱 상태는 유지
    }

    if (_initialized == true) {
      notifyListeners();
    }
  }
}
