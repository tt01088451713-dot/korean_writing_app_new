// lib/config/app_flags.dart
/// 앱 전역 토글/실험 플래그
class AppFlags {
  /// 학습자용 단순 모드: 상단의 고급 아이콘/툴을 숨깁니다.
  static const bool hideAdvancedTools = true;

  /// 개발 도구 메뉴 노출 여부(원하면 false)
  static const bool showDevMenu = true;

  /// JSON 테스트 메뉴 사용 여부
  static const bool useJsonTest = true;

  // ── 호환용 별칭(예전 코드에서 사용) ─────────────────────────────
  /// (구) hideAdvanced 를 참조하는 코드용 별칭
  static const bool hideAdvanced = hideAdvancedTools;
}
