// lib/lang_state.dart
export 'i18n/language_state.dart';
import 'package:flutter/foundation.dart';

/// 앱 전역 언어 코드 관리 ('ko','en','ja','zh','vi','fr','de','es','ru','mn')
class AppLang {
  static final ValueNotifier<String> _lang = ValueNotifier<String>('ko');

  static String get value => _lang.value;
  static set value(String v) => _lang.value = v;

  /// 편의 메서드
  static void set(String code) => _lang.value = code;

  static ValueListenable<String> get listenable => _lang;

  /// 지원 언어 목록 (요청대로 'fr' 다음에 'de' 배치)
  static const Set<String> _supported = {
    'ko', // 한국어
    'en', // 영어
    'ja', // 일본어
    'zh', // 중국어
    'vi', // 베트남어
    'fr', // 프랑스어
    'de', // 독일어 ✅
    'es', // 스페인어
    'ru', // 러시아어
    'mn', // 몽골어
  };

  static bool exists(String code) => _supported.contains(code);
  static List<String> get supported => _supported.toList(growable: false);
}
