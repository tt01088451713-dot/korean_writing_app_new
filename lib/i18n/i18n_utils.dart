// lib/i18n/i18n_utils.dart
import 'language_state.dart';

/// JSON/맵에서 언어별 필드를 뽑아옵니다.
/// 예: keyBase='title'이면 title_de → title_en → title_ko → title 순으로 폴백.
String pickI18n(Map data, String keyBase) {
  final code = LanguageState.I.code.toLowerCase(); // 예: "de" or "en-US"
  final base = code.split('-').first; // 예: "en"

  final cands = <String>[
    '${keyBase}_$code', // title_en-us
    '${keyBase}_$base', // title_en
    '${keyBase}_en', // 영문 폴백
    '${keyBase}_ko', // 한국어 폴백
    keyBase, // 접미사 없는 기본키(있으면 사용)
  ];

  for (final k in cands) {
    final v = data[k];
    if (v is String && v.trim().isNotEmpty) return v;
  }
  return '';
}
