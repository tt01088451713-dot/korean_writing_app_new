// lib/screens/letters_loader.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class LettersIndex {
  final String id;
  final Map<String, dynamic>? overview; // {title, description} (다국어 맵 허용)
  final List<LettersSection> sections; // 2.1, 2.2, 2.3, 2.4 등

  LettersIndex({required this.id, this.overview, required this.sections});
}

class LettersSection {
  final String id; // '2.1' 등
  final Map<String, dynamic>? label; // {ko:..., en:...} 또는 String
  final List<LettersCard> cards; // 카드(1개 또는 2개)

  LettersSection({required this.id, this.label, required this.cards});
}

class LettersCard {
  final String id; // ex) '2.2-A'
  final Map<String, dynamic>? label; // 카드 레이블(다국어/문자)
  final String? overviewRef; // 카드 개요 JSON 경로(선택)
  final List<String> assetRoutes; // 이 카드가 여는 자산 경로들(1개 이상)
  LettersCard({
    required this.id,
    this.label,
    this.overviewRef,
    required this.assetRoutes,
  });
}

class LettersLoader {
  static Future<LettersIndex> load(String indexAssetPath) async {
    final raw = await rootBundle.loadString(indexAssetPath);
    final data = jsonDecode(raw);

    // 최상위 id
    final rootId =
        (data is Map && data['id'] != null) ? data['id'].toString() : 'letters';

    // 개요(있으면 유지)
    final overview = (data is Map && data['overview'] is Map)
        ? (data['overview'] as Map).cast<String, dynamic>()
        : (data is Map && data['overviewRef'] != null
            ? {'overviewRef': data['overviewRef']}
            : null);

    // 섹션/카드 파싱(형식 변동에도 견고하게)
    final sections = <LettersSection>[];

    // 관용 필드: sections/cards
    final dynSections =
        (data is Map) ? (data['sections'] ?? data['cards']) : null;
    final List list = (dynSections is List) ? dynSections : const [];
    for (final s in list) {
      if (s is! Map) continue;
      final sid = (s['id'] ?? s['code'] ?? '').toString();
      final label = (s['label'] is Map || s['label'] is String)
          ? s['label'] as dynamic
          : null;

      // 카드 배열
      final dynCards = (s['cards'] is List) ? s['cards'] as List : const [];
      final cards = <LettersCard>[];
      for (int i = 0; i < dynCards.length; i++) {
        final c = dynCards[i];
        if (c is! Map) continue;
        final cid = (c['id'] ?? '$sid-${i + 1}').toString();
        final clabel = (c['label'] is Map || c['label'] is String)
            ? c['label'] as dynamic
            : null;
        final overviewRef =
            (c['overviewRef']?.toString().trim().isNotEmpty ?? false)
                ? c['overviewRef'].toString().trim()
                : null;

        // assets: route/seq/glyphs 등 여러 케이스 흡수
        final assets = <String>[];
        if (c['assets'] is List) {
          for (final a in (c['assets'] as List)) {
            if (a is String && a.trim().isNotEmpty) assets.add(a.trim());
            if (a is Map && a['route'] is String) {
              assets.add(a['route'].toString());
            }
          }
        } else if (c['route'] is String) {
          assets.add(c['route'].toString());
        } else if (c['index'] is String) {
          assets.add(c['index'].toString());
        }

        // 비어있지 않게 폴백
        if (assets.isEmpty && c['seq'] is List) {
          // seq만 존재한다면, 이 카드 자체를 JsonTest로 열 수 있게 임시 더미 마커
          assets.add('__inline__'); // 화면에서 감지해 raw seq로 처리(선택)
        }

        cards.add(LettersCard(
          id: cid,
          label: clabel as Map<String, dynamic>?,
          overviewRef: overviewRef,
          assetRoutes: assets,
        ));
      }

      sections.add(LettersSection(
          id: sid, label: label as Map<String, dynamic>?, cards: cards));
    }

    return LettersIndex(id: rootId, overview: overview, sections: sections);
  }

  /// overviewRef JSON을 로드해서 {title, description}을 돌려줍니다.
  static Future<Map<String, dynamic>?> tryLoadOverview(String? ref) async {
    if (ref == null || ref.isEmpty) return null;
    try {
      final raw = await rootBundle.loadString(ref);
      final v = jsonDecode(raw);
      return (v is Map) ? v.cast<String, dynamic>() : null;
    } catch (_) {
      return null;
    }
  }
}
