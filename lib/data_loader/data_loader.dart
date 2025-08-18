import 'dart:convert';
import 'package:flutter/services.dart';

/// Loads JSON character data from the assets/data/ directory
Future<List<dynamic>> loadCharData(String filename) async {
  final String response = await rootBundle.loadString('assets/data/$filename');
  final data = await json.decode(response);
  return data['chars'];
}
Future<Map<String, dynamic>> loadJsonAsset(String assetPath) async {
  final raw = await rootBundle.loadString(assetPath, cache: false);
  return json.decode(raw) as Map<String, dynamic>;
}

