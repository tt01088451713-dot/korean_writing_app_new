import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class JsonLoader {
  static Future<Map<String, dynamic>> loadJson(String path) async {
    final String raw = await rootBundle.loadString(path);
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> loadFrequencyTags() async {
    return loadJson('assets/data/common/frequency_tags.json');
  }
}
