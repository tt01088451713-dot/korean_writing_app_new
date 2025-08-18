import 'package:korean_writing_app_new/lang_state.dart';
import 'lang_state.dart';

/// 현재 전역 langState에 설정된 기본/보조 언어에 따라
/// 다국어 Map 또는 String에서 텍스트를 추출
String pickText(dynamic v) {
  final pair = AppLang.value;

  final p = _pickOne(v, pair.primary); // 기본 언어
  final s = pair.secondary == null ? null : _pickOne(v, pair.secondary!); // 보조 언어

  if (s == null || s.isEmpty || s == p) return p; // 보조 언어가 없거나 기본과 같으면 기본만 표시
  return '$p\n($s)'; // A안: 기본 \n(보조)
}

/// 하나의 언어 코드에 맞는 텍스트를 추출
String _pickOne(dynamic v, String code) {
  // {ko: "자음자", en: "Consonantal Letters", ...}
  if (v is Map && v[code] != null) return v[code].toString();

  // {"title": {ko: "...", en: "..."}}
  if (v is Map && v['title'] is Map && v['title'][code] != null) {
    return v['title'][code].toString();
  }

  // 단일 문자열
  if (v is String) return v;

  // {"title": "자음자"}
  if (v is Map && v['title'] is String) return v['title'];

  return '';
}
