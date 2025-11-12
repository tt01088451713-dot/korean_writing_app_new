// lib/text_pick.dart
import 'package:korean_writing_app_new/lang_state.dart';

/// 현재 전역 AppLang.value(다국어 상태)에 따라
/// 다국어 Map 또는 String에서 표시용 텍스트를 안전하게 선택.
/// - AppLang.value가 String('ko') / Map({'primary':'ko','secondary':'en'}) / 커스텀 객체 모두 허용
/// - v가 String / {ko: "...", en: "..."} / {"title": {ko: "...", ...}} / {"title": "..."} 모두 허용
/// - 보조 언어가 없거나 기본과 동일하면 기본만 반환
String pickText(dynamic v) {
  final primary = _primaryCode(AppLang.value) ?? 'ko';
  final secondary = _secondaryCode(AppLang.value);

  final p = _pickOne(v, primary);
  if (secondary == null || secondary.isEmpty) return p;

  final s = _pickOne(v, secondary);
  if (s.isEmpty || s == p) return p;

  return '$p\n($s)';
}

/// 단일 언어 코드에 맞는 텍스트 선택 (견고한 폴백 포함)
String _pickOne(dynamic v, String code) {
  final c = _norm(code);

  // 1) 단일 문자열
  if (v is String) return v.trim();

  // 2) {"title": "자음자"}
  if (v is Map && v['title'] is String) {
    return (v['title'] as String).trim();
  }

  // 3) {"title": {ko: "...", en: "..."}}
  if (v is Map && v['title'] is Map) {
    final got = _fromLangMap(v['title'] as Map, c);
    if (got.isNotEmpty) return got;
  }

  // 4) {ko: "...", en: "..."} 직접 매핑
  if (v is Map) {
    final got = _fromLangMap(v, c);
    if (got.isNotEmpty) return got;
  }

  // 5) 최후 폴백: v가 Map이면 그 안의 첫 번째 String 값
  if (v is Map) {
    for (final entry in v.entries) {
      final val = entry.value;
      if (val is String && val.trim().isNotEmpty) {
        return val.trim();
      }
      if (val is Map) {
        final nested = _fromLangMap(val, c);
        if (nested.isNotEmpty) return nested;
      }
    }
  }

  // 비어 있으면 빈 문자열
  return '';
}

/// 언어 맵에서 (ko-KR → ko 포함) 안전하게 값을 찾는다.
String _fromLangMap(Map m, String code) {
  final c = _norm(code);
  final bases = <String>{c, _base(c)}; // e.g., 'ko-KR' → {'ko-kr','ko'}

  // 대소문/구분자 변형까지 모두 시도
  final candidates = <String>{
    ...bases,
    for (final b in bases) b.toLowerCase(),
    for (final b in bases) b.toUpperCase(),
    for (final b in bases) b.replaceAll('_', '-'),
    for (final b in bases) b.replaceAll('-', '_'),
  };

  for (final key in candidates) {
    final val = m[key];
    if (val is String && val.trim().isNotEmpty) return val.trim();

    // {"ko": {...}} 같은 중첩일 때, 그 안에서 title/기본 문자열 추출
    if (val is Map) {
      final nestedTitle = val['title'];
      if (nestedTitle is String && nestedTitle.trim().isNotEmpty) {
        return nestedTitle.trim();
      }
    }
  }

  return '';
}

/// AppLang.value에서 기본 언어코드 추출
/// - String이면 그대로
/// - Map이면 primary 키 시도
/// - 커스텀 객체면 toString()이 코드라 가정(최후 수단)
String? _primaryCode(dynamic src) {
  if (src == null) return null;

  // String: "ko"
  if (src is String) return _norm(src);

  // Map: {'primary':'ko', 'secondary':'en'}
  if (src is Map) {
    final v = src['primary'];
    if (v is String && v.trim().isNotEmpty) return _norm(v);
    // 혹시 'main' 키 등 다른 네이밍을 썼을 가능성도 보조적으로 체크
    final alt = src['main'] ?? src['default'] ?? src['lang'];
    if (alt is String && alt.trim().isNotEmpty) return _norm(alt);
  }

  // 커스텀 객체: toString()이 코드로 제공되는 경우(최후 수단)
  final s = src.toString();
  if (s.isNotEmpty &&
      s != 'Instance of \'Object\'' &&
      s != src.runtimeType.toString()) {
    return _norm(s);
  }
  return null;
}

/// AppLang.value에서 보조 언어코드 추출(없으면 null)
String? _secondaryCode(dynamic src) {
  if (src == null) return null;

  if (src is String) {
    // 단일 코드만 제공되면 보조 없음
    return null;
  }

  if (src is Map) {
    final v = src['secondary'] ?? src['sub'] ?? src['fallback'];
    if (v is String && v.trim().isNotEmpty) return _norm(v);
    return null;
  }

  // 커스텀 객체: 보조 언어가 없다면 null
  return null;
}

/// 코드 정규화: 공백제거, 소문자화
String _norm(String code) => code.trim().toLowerCase();

/// 'ko-kr' → 'ko'
String _base(String code) {
  final idx = code.indexOf(RegExp(r'[-_]'));
  return (idx > 0) ? code.substring(0, idx) : code;
}
