import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class LettersCategory {
  // 2_1..2_4
  final String id;
  final String route; // either *_index.json or *_hub_index.json
  final String? overviewRef;
  final Map<String, dynamic>? title; // optional per‑lang title
  LettersCategory(
      {required this.id, required this.route, this.overviewRef, this.title});
}

class LettersMasterIndex {
  final String? overviewRef; // whole Letters overview
  final List<LettersCategory> cats; // 4 categories
  LettersMasterIndex({this.overviewRef, required this.cats});

  static Future<LettersMasterIndex> load() async {
    final raw = await rootBundle.loadString('assets/data/letters/2_index.json');
    final m = json.decode(raw) as Map<String, dynamic>;
    final cats = ((m['categories'] ?? []) as List)
        .map((e) => LettersCategory(
              id: e['id'],
              route: e['route'],
              overviewRef: e['overviewRef'],
              title: (e['title'] is Map<String, dynamic>)
                  ? (e['title'] as Map<String, dynamic>)
                  : null,
            ))
        .toList();
    return LettersMasterIndex(
        overviewRef: m['overviewRef'] as String?, cats: cats);
  }
}

class LettersHubData {
  // for 2_2/2_3/2_4 hub pages
  final String? title;
  final String? overviewRef;
  final List<HubCard> cards;
  LettersHubData({this.title, this.overviewRef, required this.cards});
  static Future<LettersHubData> load(String asset) async {
    final raw = await rootBundle.loadString(asset);
    final m = json.decode(raw) as Map<String, dynamic>;
    final cards = ((m['cards'] ?? []) as List)
        .map((e) => HubCard(
              id: e['id'] ?? '',
              title: e['title'] ?? '',
              route: e['route'] as String,
            ))
        .toList();
    return LettersHubData(
        title: m['title'] as String?,
        overviewRef: m['overviewRef'] as String?,
        cards: cards);
  }
}

class HubCard {
  final String id;
  final String title;
  final String route;
  HubCard({required this.id, required this.title, required this.route});
}

class UnitSyllable {
  final String glyph;
  final String? hint;
  const UnitSyllable(this.glyph, this.hint);
}

class LettersUnitData {
  final String titleI18nKey;
  final List<UnitSyllable> items;
  LettersUnitData({required this.titleI18nKey, required this.items});
}

class LettersLoader {
  static Future<String?> loadOverview(String? ref) async {
    if (ref == null) return null;
    try {
      final raw = await rootBundle.loadString(ref);
      final m = json.decode(raw);
      if (m is Map && m['body'] is String) {
        return m['body'] as String; // body preferred
      }
      if (m is Map && m['description'] is Map) {
// if multilingual descriptions exist, choose 'ko' first then 'en'
        final desc = m['description'] as Map;
        return (desc['ko'] ?? desc['en'] ?? '').toString();
      }
      if (m is Map && m['desc'] is String) return m['desc'] as String;
      return raw; // fallback raw
    } catch (_) {
      return null;
    }
  }

  static Future<LettersUnitData> loadUnit(String asset) async {
    final raw = await rootBundle.loadString(asset);
    final m = json.decode(raw) as Map<String, dynamic>;
    final syll = ((m['syllables'] ?? []) as List)
        .map((e) => UnitSyllable(e['glyph'], e['hint']))
        .toList();
    return LettersUnitData(
        titleI18nKey: (m['titleI18nKey'] ?? 'letters') as String, items: syll);
  }
}
