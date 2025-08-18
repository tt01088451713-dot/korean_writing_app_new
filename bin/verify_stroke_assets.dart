// bin/verify_stroke_assets.dart
//
// 목표 (가벼운 기본형):
// 1) 자음/모음 JSON에서 id를 모아서
// 2) assets/images/strokes/{consonants|vowels}/<id>.png 또는 .json 존재 확인
// 3) 누락/고아(자산만 있고 JSON 없음) 간단 리포트

import 'dart:convert';
import 'dart:io';

const consonantJson = 'assets/data/1_1_consonantal_letter.json';
const vowelJson     = 'assets/data/1_2_vowel_letter.json';
const consDir       = 'assets/images/strokes/consonants';
const vowelDir      = 'assets/images/strokes/vowels';

void main() async {
  final errors = <String>[];
  final warns  = <String>[];

  // JSON 로드
  final consMap = jsonDecode(await File(consonantJson).readAsString(encoding: utf8)) as Map;
  final vowMap  = jsonDecode(await File(vowelJson).readAsString(encoding: utf8)) as Map;

  // id 수집
  final consIds = _collectIds(consMap);
  final vowIds  = _collectIds(vowMap);

  // 자산 stem 수집(확장자 제거)
  final consStems  = _collectStems(consDir);
  final vowelStems = _collectStems(vowelDir);

  // 누락 검사 (JSON → 자산)
  for (final id in consIds) {
    if (!consStems.contains(id)) {
      errors.add('자음: 자산 누락 → $consDir/$id.(png|json)');
    }
  }
  for (final id in vowIds) {
    // 아래아(ㆍ)는 연습 제외라면 누락 허용하고 싶으면 주석 해제
    // if (id == 'arae_a') continue;
    if (!vowelStems.contains(id)) {
      errors.add('모음: 자산 누락 → $vowelDir/$id.(png|json)');
    }
  }

  // 고아 자산 검사 (자산 → JSON)
  for (final stem in consStems.difference(consIds)) {
    warns.add('자음: JSON에 없음(고아 자산) → $consDir/$stem.(png|json)');
  }
  for (final stem in vowelStems.difference(vowIds)) {
    warns.add('모음: JSON에 없음(고아 자산) → $vowelDir/$stem.(png|json)');
  }

  // 결과 출력
  print('=== Stroke Asset Verify (basic) ===');
  print('- JSON 자음 수: ${consIds.length}, 자산 수: ${consStems.length}');
  print('- JSON 모음 수: ${vowIds.length}, 자산 수: ${vowelStems.length}\n');

  if (errors.isEmpty) {
    print('✅ ERROR 없음');
  } else {
    print('❌ ERROR 목록 (${errors.length})');
    for (final e in errors) {
      print('  - $e');
    }
  }
  print('');
  if (warns.isEmpty) {
    print('ℹ️  경고 없음');
  } else {
    print('⚠️  경고 목록 (${warns.length})');
    for (final w in warns) {
      print('  - $w');
    }
  }

  if (errors.isNotEmpty) exitCode = 1;
}

Set<String> _collectIds(Map m) {
  final ids = <String>{};
  final parts = (m['parts'] ?? []) as List;
  for (final p in parts) {
    final chars = (p['chars'] ?? []) as List;
    for (final c in chars) {
      final id = '${(c as Map)['id'] ?? ''}'.trim();
      if (id.isNotEmpty) ids.add(id);
    }
  }
  return ids;
}

Set<String> _collectStems(String dirPath) {
  final dir = Directory(dirPath);
  if (!dir.existsSync()) return {};
  final stems = <String>{};
  for (final e in dir.listSync(recursive: false, followLinks: false)) {
    if (e is File) {
      final name = e.uri.pathSegments.last;
      final dot  = name.lastIndexOf('.');
      if (dot > 0) {
        final stem = name.substring(0, dot);
        final ext  = name.substring(dot + 1).toLowerCase();
        if (ext == 'png' || ext == 'json') stems.add(stem);
      }
    }
  }
  return stems;
}
