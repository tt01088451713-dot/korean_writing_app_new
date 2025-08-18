// lib/utils/stroke_path.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// 자음/모음 구분
enum LetterKind { consonant, vowel }

/// 획순 자산 탐색 유틸:
/// - 규칙: id 우선 → glyph 보조
/// - 경로: assets/images/strokes/consonants|vowels/<id>.json(.png 폴백)
/// - 존재하지 않으면 null
class StrokePath {
  static const String _consonantDir = 'assets/images/strokes/consonants/';
  static const String _vowelDir = 'assets/images/strokes/vowels/';

  /// AssetManifest.json을 1회 로드/캐시해서 자산 존재 여부를 빠르게 검사
  static Map<String, dynamic>? _assetManifest;
  static Set<String>? _assetSet;

  static Future<void> _ensureAssetManifest() async {
    if (_assetManifest != null && _assetSet != null) return;
    final raw = await rootBundle.loadString('AssetManifest.json');
    _assetManifest = json.decode(raw) as Map<String, dynamic>;
    _assetSet = _assetManifest!.keys.toSet();
  }

  /// 주어진 경로의 자산이 존재하면 true
  static Future<bool> _exists(String path) async {
    await _ensureAssetManifest();
    return _assetSet!.contains(path);
  }

  /// 주어진 id로 자산을 찾는다. (우선 .json, 없으면 .png)
  static Future<String?> _byId(LetterKind kind, String id) async {
    if (id.isEmpty) return null;
    final dir = kind == LetterKind.consonant ? _consonantDir : _vowelDir;
    final jsonPath = '$dir$id.json';
    if (await _exists(jsonPath)) return jsonPath;
    final pngPath = '$dir$id.png';
    if (await _exists(pngPath)) return pngPath;
    return null;
  }

  /// glyph → 표준 id 매핑 (필요 항목만 정의)
  /// - 자음: 프로젝트 정책상 사용되는 글자만 등록
  /// - 모음: ㆍ 제외 모두 등록 (ㆍ은 설명용이라 획순 없음)
  static const Map<String, String> _glyphToIdConsonant = {
    // 기본자
    'ㄱ': 'giyeok',
    'ㄴ': 'nieun',
    'ㅁ': 'mieum',
    'ㅅ': 'siot',
    'ㅇ': 'ieung',
    // 가획자
    'ㅋ': 'kieuk',
    'ㄷ': 'digeut',
    'ㅌ': 'tieut',
    'ㅂ': 'bieup',
    'ㅍ': 'pieup',
    'ㅈ': 'jieut',
    'ㅊ': 'chieut',
    'ㅎ': 'hieut',
    // 이체자
    'ㄹ': 'rieul',
    // (필요 시 된소리/기타 추가 가능)
  };

  static const Map<String, String> _glyphToIdVowel = {
    // 기본자(ㆍ은 생략: 설명 전용)
    'ㅡ': 'eu',
    'ㅣ': 'i',
    // 초출자
    'ㅏ': 'a',
    'ㅓ': 'eo',
    'ㅗ': 'o',
    'ㅜ': 'u',
    // 재출자
    'ㅑ': 'ya',
    'ㅕ': 'yeo',
    'ㅛ': 'yo',
    'ㅠ': 'yu',
    // ㅣ상합자
    'ㅐ': 'ae',
    'ㅔ': 'e',
    'ㅒ': 'yae',
    'ㅖ': 'ye',
    'ㅚ': 'oe',
    'ㅟ': 'wi',
    'ㅢ': 'ui',
    'ㅙ': 'wae',
    'ㅞ': 'we',
    // 이자합용자
    'ㅘ': 'wa',
    'ㅝ': 'wo',
  };

  /// 공개 API ─────────────────────────────────────────────────────

  /// (권장) id 우선 → glyph 보조로 획순 자산 경로를 찾는다.
  /// - 반환: 경로(String) 또는 null
  static Future<String?> find({
    required LetterKind kind,
    String? id,
    String? glyph,
  }) async {
    // 1) id가 오면 그대로 시도
    if (id != null && id.trim().isNotEmpty) {
      final p = await _byId(kind, id.trim());
      if (p != null) return p;
    }
    // 2) glyph → id 매핑 후 시도
    if (glyph != null && glyph.trim().isNotEmpty) {
      final mapped = _mapGlyphToId(kind, glyph.trim());
      if (mapped != null) {
        final p = await _byId(kind, mapped);
        if (p != null) return p;
      }
    }
    return null;
  }

  /// glyph만 있을 때도 호출 가능 (편의 함수)
  static Future<String?> findByGlyph(LetterKind kind, String glyph) {
    return find(kind: kind, glyph: glyph);
  }

  /// id만 있을 때도 호출 가능 (편의 함수)
  static Future<String?> findById(LetterKind kind, String id) {
    return find(kind: kind, id: id);
  }

  /// 자산 파일이 있는지 간단히 알고 싶을 때
  static Future<bool> hasAsset({
    required LetterKind kind,
    String? id,
    String? glyph,
  }) async {
    return (await find(kind: kind, id: id, glyph: glyph)) != null;
  }

  /// 내부 매핑 도우미
  static String? _mapGlyphToId(LetterKind kind, String glyph) {
    if (kind == LetterKind.consonant) {
      return _glyphToIdConsonant[glyph];
    } else {
      return _glyphToIdVowel[glyph];
    }
  }
}
