import 'package:flutter/foundation.dart';

/// 앱 전역 언어 코드 관리 ('ko','en','ja','zh','vi' ...)
class AppLang {
  static final ValueNotifier<String> _lang = ValueNotifier<String>('ko');

  static String get value => _lang.value;
  static set value(String v) => _lang.value = v;

  /// 편의 메서드
  static void set(String code) => _lang.value = code;

  static ValueListenable<String> get listenable => _lang;

  static const Set<String> _supported = {
    'ko','en','ja','zh','vi','fr','es','ru','mn'
  };

  static bool exists(String code) => _supported.contains(code);
  static List<String> get supported => _supported.toList(growable: false);
}
