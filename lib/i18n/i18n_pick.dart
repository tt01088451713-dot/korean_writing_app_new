// lib/i18n/i18n_pick.dart
import 'package:korean_writing_app_new/i18n/language_state.dart';

/// 다국어 값( {ko: "...", en: "..."} ) 또는 단일 문자열을 받아
/// 현재 언어에 맞는 문자열로 변환합니다.
String tr(dynamic v, {String? fallback}) {
  if (v == null) return fallback ?? '';
  if (v is String) return v;
  if (v is Map) {
    final code = LanguageState.I.code.toLowerCase();
    final base = code.split('-').first;
    // 우선순위: full code → base → en → ko → 첫 값
    String? pick(Object? x) => (x is String && x.trim().isNotEmpty) ? x : null;
    return pick(v[code]) ??
        pick(v[base]) ??
        pick(v['en']) ??
        pick(v['ko']) ??
        v.values.whereType<String>().firstWhere(
              (s) => s.trim().isNotEmpty,
              orElse: () => fallback ?? '',
            );
  }
  return v.toString();
}

/// JSON 오브젝트에서 title/description을 한 번에 꺼내는 헬퍼
/// - 각 필드는 다국어 맵 또는 문자열일 수 있음
class LocalizedOverview {
  final String title;
  final String description;
  const LocalizedOverview({this.title = '', this.description = ''});
}

LocalizedOverview pickOverview(Map<String, dynamic> m) {
  final title = tr(m['title'], fallback: '');
  final desc = tr(m['description'], fallback: '');
  return LocalizedOverview(title: title, description: desc);
}
