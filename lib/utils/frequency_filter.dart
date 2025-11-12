import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class FrequencyFilter {
  bool hideRare;
  final Set<String> rareSet;

  FrequencyFilter._(this.rareSet, {required this.hideRare});

  static Future<FrequencyFilter> load({
    String path = 'assets/data/common/frequency_tags.json',
    bool defaultHideRare = true,
  }) async {
    final raw = await rootBundle.loadString(path);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final tags = (json['tags'] ?? {}) as Map<String, dynamic>;
    final rare = (tags['rare']?['examples'] ?? []) as List<dynamic>;
    final hideRareDefault =
        (json['hideRareDefault'] ?? defaultHideRare) as bool;
    return FrequencyFilter._(
      rare.map((e) => e.toString()).toSet(),
      hideRare: hideRareDefault,
    );
  }

  List<String> apply(List<String> sequence) => hideRare
      ? sequence.where((s) => !rareSet.contains(s)).toList()
      : sequence;
}
