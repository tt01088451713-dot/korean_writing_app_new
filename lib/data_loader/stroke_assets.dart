// lib/data_loader/stroke_assets.dart
// 자음/모음 쓰기 가이드 PNG 경로 매핑 + 유틸

class StrokeAssets {
  // 경로 베이스
  static const String _baseCons = 'assets/images/strokes/consonants/';
  static const String _baseVows = 'assets/images/strokes/vowels/';

  /// 자모 → PNG 경로
  static const Map<String, String> _map = {
    // ───── 자음(기본 14) ─────
    'ㄱ': '${_baseCons}stroke_ㄱ.png',
    'ㄴ': '${_baseCons}stroke_ㄴ.png',
    'ㄷ': '${_baseCons}stroke_ㄷ.png',
    'ㄹ': '${_baseCons}stroke_ㄹ.png',
    'ㅁ': '${_baseCons}stroke_ㅁ.png',
    'ㅂ': '${_baseCons}stroke_ㅂ.png',
    'ㅅ': '${_baseCons}stroke_ㅅ.png',
    'ㅇ': '${_baseCons}stroke_ㅇ.png',
    'ㅈ': '${_baseCons}stroke_ㅈ.png',
    'ㅊ': '${_baseCons}stroke_ㅊ.png',
    'ㅋ': '${_baseCons}stroke_ㅋ.png',
    'ㅌ': '${_baseCons}stroke_ㅌ.png',
    'ㅍ': '${_baseCons}stroke_ㅍ.png',
    'ㅎ': '${_baseCons}stroke_ㅎ.png',

    // 쌍자음(각자병서) 5
    'ㄲ': '${_baseCons}stroke_ㄲ.png',
    'ㄸ': '${_baseCons}stroke_ㄸ.png',
    'ㅃ': '${_baseCons}stroke_ㅃ.png',
    'ㅆ': '${_baseCons}stroke_ㅆ.png',
    'ㅉ': '${_baseCons}stroke_ㅉ.png',

    // 합용병서 11 (가이드 전용)
    'ㄳ': '${_baseCons}stroke_ㄱ_ㅅ.png',
    'ㄵ': '${_baseCons}stroke_ㄴ_ㅈ.png',
    'ㄶ': '${_baseCons}stroke_ㄴ_ㅎ.png',
    'ㄺ': '${_baseCons}stroke_ㄹ_ㄱ.png',
    'ㄻ': '${_baseCons}stroke_ㄹ_ㅁ.png',
    'ㄼ': '${_baseCons}stroke_ㄹ_ㅂ.png',
    'ㄽ': '${_baseCons}stroke_ㄹ_ㅅ.png',
    'ㄾ': '${_baseCons}stroke_ㄹ_ㅌ.png',
    'ㄿ': '${_baseCons}stroke_ㄹ_ㅍ.png',
    'ㅀ': '${_baseCons}stroke_ㄹ_ㅎ.png',
    'ㅄ': '${_baseCons}stroke_ㅂ_ㅅ.png',

    // ───── 모음(기본/이중모음) ─────
    // 기본 10
    'ㅏ': '${_baseVows}a.png',
    'ㅑ': '${_baseVows}ya.png',
    'ㅓ': '${_baseVows}eo.png',
    'ㅕ': '${_baseVows}yeo.png',
    'ㅗ': '${_baseVows}o.png',
    'ㅛ': '${_baseVows}yo.png',
    'ㅜ': '${_baseVows}u.png',
    'ㅠ': '${_baseVows}yu.png',
    'ㅡ': '${_baseVows}eu.png',
    'ㅣ': '${_baseVows}i.png',

    // 이중모음 11
    'ㅐ': '${_baseVows}ae.png',
    'ㅔ': '${_baseVows}e.png',
    'ㅘ': '${_baseVows}wa.png',
    'ㅙ': '${_baseVows}wae.png',
    'ㅚ': '${_baseVows}oe.png',
    'ㅝ': '${_baseVows}wo.png',
    'ㅞ': '${_baseVows}we.png',
    'ㅟ': '${_baseVows}wi.png',
    'ㅢ': '${_baseVows}ui.png',
    'ㅖ': '${_baseVows}ye.png',
    'ㅒ': '${_baseVows}yae.png', // 일부 교재 표기(파일이 있을 때만 사용)
  };

  /// 합용병서(쓰기 없음, 가이드만) 집합 — 자음에만 해당
  static const Set<String> compositeByeongseo = {
    'ㄳ',
    'ㄵ',
    'ㄶ',
    'ㄺ',
    'ㄻ',
    'ㄼ',
    'ㄽ',
    'ㄾ',
    'ㄿ',
    'ㅀ',
    'ㅄ',
  };

  /// 합용병서 여부(자음 병서 전용)
  static bool isComposite(String glyph) => compositeByeongseo.contains(glyph);

  /// 지정된 자모의 PNG 경로 반환
  static String? get(String glyph) {
    final direct = _map[glyph];
    if (direct != null) return direct;

    // 자음 병서 두 글자 조합이면 규칙 기반 추론 (예: ㄱㅅ → stroke_ㄱ_ㅅ.png)
    if (glyph.runes.length == 2) {
      final r = glyph.runes.toList();
      final a = String.fromCharCode(r[0]);
      final b = String.fromCharCode(r[1]);
      return '${_baseCons}stroke_${a}_$b.png';
    }
    return null;
  }

  static bool has(String glyph) => get(glyph) != null;

  static List<String> allKnown() => _map.values.toList(growable: false);
}
