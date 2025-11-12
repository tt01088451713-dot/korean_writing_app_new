// lib/i18n/language_state.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 전역 언어 상태를 관리하는 싱글톤 ChangeNotifier.
/// - 사용: LanguageState.I.code  /  await LanguageState.I.set('en')
/// - 초기화: main() 에서 runApp 이전에 await LanguageState.init()
class LanguageState extends ChangeNotifier {
  LanguageState._internal();
  static final LanguageState I = LanguageState._internal();

  static const String _prefKey = 'app_language_code';
  static const String _fallback = 'ko';

  String _code = _fallback;
  bool _inited = false;

  /// 현재 언어 코드 (예: ko, en, ja, zh, de ...)
  String get code => _code;

  /// ─────────────────────────────────────────────────────────
  /// 지원 언어: UI 표시 순서를 이 리스트 순서로 고정
  /// 요청하신 순서: 한국어, 영어, 일본어, 중국어, 베트남어, 프랑스어, 독일어, 스페인어, 러시아어, 몽골어
  static List<LanguageInfo> get supported => kSupportedLanguages;

  /// 지원 여부 체크
  static bool isSupported(String code) {
    final norm = _normalize(code);
    for (final li in kSupportedLanguages) {
      if (norm == li.code || norm.startsWith('${li.code}-')) return true;
    }
    return false;
  }

  /// code를 지원 언어의 표준 코드로 정규화(ko-KR -> ko 등)
  static String _canonicalize(String code) {
    final norm = _normalize(code.isEmpty ? _fallback : code);
    for (final li in kSupportedLanguages) {
      if (norm == li.code || norm.startsWith('${li.code}-')) {
        return li.code;
      }
    }
    return _fallback;
  }

  /// ─────────────────────────────────────────────────────────

  /// 언어 코드 정규화(소문자, 공백 제거)
  static String _normalize(String v) => v.trim().toLowerCase();

  /// 앱 시작 시 저장된 언어를 불러와 메모리에 반영.
  /// runApp 이전에 딱 1회 호출하세요.
  static Future<void> init() async {
    if (I._inited) return;
    try {
      final sp = await SharedPreferences.getInstance();
      final saved = sp.getString(_prefKey);
      if (saved != null && saved.isNotEmpty) {
        I._code = _canonicalize(saved);
      } else {
        I._code = _fallback;
      }
    } catch (_) {
      I._code = _fallback;
    }
    I._inited = true;

    // 레거시(AppLang)와 값 동기화
    try {
      AppLang._setSilently(I._code);
    } catch (_) {}

    // 초기 진입 시에도 구독자가 있으면 리빌드되도록 알림
    I.notifyListeners();
  }

  /// 언어 변경 + 영구 저장 + 전역 리빌드 트리거
  Future<void> set(String next) async {
    final canon = _canonicalize(next.isEmpty ? _fallback : next);
    if (canon == _code) return;

    _code = canon;

    // 레거시(AppLang)와 값 동기화
    try {
      AppLang._setSilently(_code);
    } catch (_) {}

    notifyListeners();

    // 저장 실패는 치명적이지 않으므로 무시
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_prefKey, _code);
    } catch (_) {}
  }
}

/// ─────────────────────────────────────────────────────────────
/// 레거시 호환용 AppLang
///   - 과거 코드가 AppLang.value / AppLang.set(...) / AppLang.load() 등을
///     참조하더라도 정상 동작하도록 브리지 제공.
///   - 내부적으로 LanguageState.I 와 양방향 동기화.
/// ─────────────────────────────────────────────────────────────
class AppLang {
  AppLang._();

  static final ValueNotifier<String> _lang = ValueNotifier<String>('ko');

  /// 과거 코드에서 사용하던 현재 언어 값
  static String get value => _lang.value;
  static set value(String v) => _lang.value = LanguageState._normalize(v);

  /// 과거 코드에서 사용하던 리스너블(예: ValueListenableBuilder 등)
  static ValueListenable<String> get listenable => _lang;

  static const String _prefKey = LanguageState._prefKey;

  /// 내부에서만 호출: 노티파이 없이 값만 맞춤
  static void _setSilently(String v) {
    final norm = LanguageState._canonicalize(v);
    if (_lang.value != norm) {
      _lang.value = norm;
    }
  }

  /// 저장된 언어 불러오기(레거시 API).
  /// - LanguageState.I에도 동일 값 반영.
  static Future<void> load() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final saved = sp.getString(_prefKey);
      if (saved != null && saved.isNotEmpty) {
        final canon = LanguageState._canonicalize(saved);
        _setSilently(canon);
        await LanguageState.I.set(canon);
      }
    } catch (_) {}
  }

  /// 메모리에만 반영(레거시 API). LanguageState.I에도 전달.
  static Future<void> set(String code) async {
    final canon = LanguageState._canonicalize(code);
    if (canon.isEmpty || canon == _lang.value) return;
    _setSilently(canon);
    try {
      await LanguageState.I.set(canon);
    } catch (_) {}
  }

  /// 영구 저장까지 포함(레거시 API). LanguageState.I에도 전달.
  static Future<void> save(String code) async {
    final canon = LanguageState._canonicalize(code);
    if (canon.isEmpty) return;

    _setSilently(canon);
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_prefKey, canon);
    } catch (_) {}
    try {
      await LanguageState.I.set(canon);
    } catch (_) {}
  }
}

/// ─────────────────────────────────────────────────────────────
/// 지원 언어 메타
///  - UI: native/label 사용 가능
///  - code는 BCP-47의 기본 언어 코드(지역코드 제거 버전)
/// ─────────────────────────────────────────────────────────────
class LanguageInfo {
  final String code; // 'ko', 'en', ...
  final String native; // 표기(자국어)
  final String label; // UI 라벨
  const LanguageInfo(this.code, this.native, this.label);
}

/// 요청하신 순서 유지
const List<LanguageInfo> kSupportedLanguages = <LanguageInfo>[
  LanguageInfo('ko', '한국어', '한국어 (Korean)'),
  LanguageInfo('en', 'English', 'English'),
  LanguageInfo('ja', '日本語', '日本語 (Japanese)'),
  LanguageInfo('zh', '中文', '中文 (Chinese)'),
  LanguageInfo('vi', 'Tiếng Việt', 'Tiếng Việt (Vietnamese)'),
  LanguageInfo('fr', 'Français', 'Français (French)'),
  LanguageInfo('de', 'Deutsch', 'Deutsch (German)'),
  LanguageInfo('es', 'Español', 'Español (Spanish)'),
  LanguageInfo('ru', 'Русский', 'Русский (Russian)'),
  LanguageInfo('mn', 'Монгол', 'Монгол (Mongolian)'),
];
