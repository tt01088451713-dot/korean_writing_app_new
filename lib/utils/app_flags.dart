// lib/utils/app_flags.dart
import 'package:flutter/foundation.dart';

/// 앱 전반의 간단한 기능 토글 모음.
/// - 화면 코드에서 if (AppFlags.hideAdvancedTools) ... 형태로 사용
class AppFlags {
  AppFlags._();

  /// 고급(우상단) 도구 숨기기 기본값
  static final bool hideAdvancedTools = true;

  /// 글자 단원: 허브 상단에 개요 카드 노출
  static final bool lettersShowOverviewCard = true;

  /// 자모 단원: 기존 고급 도구 유지 여부 (요구사항: 자모는 잘 유지)
  static final bool jamoKeepAdvancedTools = true;

  /// 디버그 메뉴 노출 (개발 중만 유용)
  static final bool showDebugMenus = kDebugMode;

  /// Firebase 업로드 버튼 노출(전역). 실제 업로드는 각 화면 상수/로직이 따로 막을 수 있음.
  static final bool enableGlobalUploadButtons = false;
}
