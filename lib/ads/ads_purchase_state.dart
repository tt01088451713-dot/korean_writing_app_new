// lib/ads/ads_purchase_state.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 전체에서 광고 제거 여부 + 인앱 결제를 관리하는 전역 상태.
/// - 싱글톤 패턴: AdsPurchaseState.I 로 접근
/// - SharedPreferences 에 광고 제거 여부 저장
/// - 인앱 결제(Remove Ads) 로직 포함
class AdsPurchaseState extends ChangeNotifier {
  AdsPurchaseState._internal();
  static final AdsPurchaseState I = AdsPurchaseState._internal();

  // SharedPreferences 키
  static const _prefsKeyAdsRemoved = 'k_ads_removed_v1';

  // 인앱 결제 상품 ID (Play Console 의 “제품 ID” 와 일치해야 함)
  // ✅ 현재 콘솔에서 제품 ID: remove_ads → 그대로 사용하면 됨
  static const String removeAdsProductId = 'remove_ads';

  // 내부 상태
  bool _adsRemoved = false;
  bool _initialized = false;

  bool _iapAvailable = false;
  bool _isProcessing = false;

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _iapInitialized = false;

  /// 광고가 제거된 상태인지 여부
  bool get isAdsRemoved => _adsRemoved;

  /// SharedPreferences 및 IAP 초기화가 끝났는지 여부
  bool get isInitialized => _initialized;

  /// 인앱 결제가 진행 중인지 여부 (UI에서 버튼 비활성화 등에 사용)
  bool get isProcessing => _isProcessing;

  /// 최초 1회만 호출되는 지연 초기화.
  /// - SharedPreferences 에서 광고 제거 여부 로드
  /// - 인앱 결제 사용 가능 여부 확인 및 purchaseStream 구독
  Future<void> ensureLoaded() async {
    if (_initialized) return;

    // 1) prefs 로드
    try {
      final prefs = await SharedPreferences.getInstance();
      _adsRemoved = prefs.getBool(_prefsKeyAdsRemoved) ?? false;
    } catch (e) {
      debugPrint('AdsPurchaseState.ensureLoaded prefs error: $e');
    }

    // 2) 인앱 결제 초기화
    await _initIapIfNeeded();

    _initialized = true;
    notifyListeners();
  }

  Future<void> _initIapIfNeeded() async {
    if (_iapInitialized) return;

    try {
      _iapAvailable = await _iap.isAvailable();
      if (_iapAvailable) {
        _subscription = _iap.purchaseStream.listen(
          _onPurchaseUpdate,
          onDone: () {
            _subscription?.cancel();
          },
          onError: (Object error) {
            debugPrint('IAP purchaseStream error: $error');
          },
        );
      } else {
        debugPrint('IAP not available on this device/store.');
      }
    } catch (e) {
      debugPrint('AdsPurchaseState._initIapIfNeeded error: $e');
      _iapAvailable = false;
    }

    _iapInitialized = true;
  }

  /// 실제 인앱 결제 성공 후에 호출될 함수.
  Future<void> markAdsRemoved() async {
    _adsRemoved = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKeyAdsRemoved, true);
    } catch (e) {
      debugPrint('AdsPurchaseState.markAdsRemoved error: $e');
    }
  }

  /// (선택) 디버그용. 광고 제거 상태를 초기화할 때 사용.
  Future<void> resetAdsRemovedForDebug() async {
    _adsRemoved = false;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKeyAdsRemoved);
    } catch (e) {
      debugPrint('AdsPurchaseState.resetAdsRemovedForDebug error: $e');
    }
  }

  /// Remove Ads 인앱 결제 시작
  Future<void> buyRemoveAds() async {
    await ensureLoaded(); // 안전하게 초기화 보장

    // 이미 광고 제거된 상태라면 결제 시도하지 않음
    if (_adsRemoved) {
      debugPrint('Ads already removed. Skip purchase.');
      return;
    }

    if (!_iapAvailable) {
      debugPrint('IAP not available. Cannot buy remove_ads.');
      return;
    }
    if (_isProcessing) return;

    _isProcessing = true;
    notifyListeners();

    try {
      final response =
      await _iap.queryProductDetails({removeAdsProductId});

      if (response.error != null) {
        debugPrint('IAP queryProductDetails error: ${response.error}');
        return;
      }

      if (response.productDetails.isEmpty) {
        debugPrint('IAP: No product found for id $removeAdsProductId');
        return;
      }

      final productDetails = response.productDetails.first;
      final purchaseParam =
      PurchaseParam(productDetails: productDetails);

      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      // 실제 구매 결과는 purchaseStream(_onPurchaseUpdate)에서 처리
    } catch (e) {
      debugPrint('AdsPurchaseState.buyRemoveAds error: $e');
    } finally {
      // 스트림에서 별도로 상태를 갱신하더라도,
      // 여기서 한 번 더 안전하게 로딩 플래그를 해제한다.
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// 이미 구매한 Remove Ads 복원 (특히 iOS에서 중요)
  Future<void> restorePurchases() async {
    await ensureLoaded();

    if (!_iapAvailable) {
      debugPrint('IAP not available. Cannot restore purchases.');
      return;
    }
    if (_isProcessing) return;

    _isProcessing = true;
    notifyListeners();

    try {
      await _iap.restorePurchases();
      // 복원 결과도 purchaseStream을 통해 _onPurchaseUpdate로 들어옴
    } catch (e) {
      debugPrint('AdsPurchaseState.restorePurchases error: $e');
    } finally {
      // 복원할 구매가 없거나, 스트림이 호출되지 않는 경우에도
      // 반드시 로딩 상태를 해제
      _isProcessing = false;
      notifyListeners();
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      try {
        if (purchaseDetails.productID == removeAdsProductId) {
          switch (purchaseDetails.status) {
            case PurchaseStatus.pending:
              _isProcessing = true;
              notifyListeners();
              break;
            case PurchaseStatus.purchased:
            case PurchaseStatus.restored:
            // 광고 제거 권한 부여
              await markAdsRemoved();
              _isProcessing = false;
              notifyListeners();
              if (purchaseDetails.pendingCompletePurchase) {
                await _iap.completePurchase(purchaseDetails);
              }
              break;
            case PurchaseStatus.error:
              debugPrint('IAP error: ${purchaseDetails.error}');
              _isProcessing = false;
              notifyListeners();
              if (purchaseDetails.pendingCompletePurchase) {
                await _iap.completePurchase(purchaseDetails);
              }
              break;
            case PurchaseStatus.canceled:
              _isProcessing = false;
              notifyListeners();
              break;
          }
        } else {
          // (혹시 나중에 다른 상품이 생겼을 때 대비)
          if (purchaseDetails.pendingCompletePurchase) {
            await _iap.completePurchase(purchaseDetails);
          }
        }
      } catch (e) {
        debugPrint('AdsPurchaseState._onPurchaseUpdate error: $e');
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
        _isProcessing = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
