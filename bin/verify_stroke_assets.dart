// bin/verify_stroke_assets.dart
//
// 목적(강화판):
// 1) 자음/모음 JSON에서 id 수집 + 중복 감지
// 2) assets/images/strokes/{consonants|vowels}/<id>.png 또는 .json 존재 확인
// 3) 누락/고아/확장자/중복 리포트
// 4) --strict 옵션 시 경고도 실패 처리(exit 1)

import 'dart:convert';
import 'dart:io';

const consonantJson = 'assets/data/1_1_consonantal_letter.json';
const vowelJson = 'assets/data/1_2_vowel_letter.json';
const consDir = 'assets/images/strokes/consonants';
const vowelDir = 'assets/images/strokes/vowels';

// 연습 제외 등 "누락 허용" id 목록 (필요 시 여기에 추가)
const allowMissingVowelIds = <String>{
  'arae_a', // 아래아(ㆍ): 설명만 제공, 가이드/연습 자산 없어도 됨
};

// 허용되는 자산 확장자
const allowedExts = <String>{'png', 'json'};

void main(List<String> args) async {
  final strict = args.contains('--strict');

  final errors = <String>[];
  final warns = <String>[];

  // ---------- JSON 로드 ----------
  Map consMap, vowMap;
  try {
    consMap = jsonDecode(await File(consonantJson).readAsString(encoding: utf8))
        as Map;
  } catch (e) {
    stderr.writeln('❌ 자음 JSON 로드 실패: $consonantJson — $e');
    exit(1);
  }
  try {
    vowMap =
        jsonDecode(await File(vowelJson).readAsString(encoding: utf8)) as Map;
  } catch (e) {
    stderr.writeln('❌ 모음 JSON 로드 실패: $vowelJson — $e');
    exit(1);
  }

  // ---------- id 수집 + 중복 감지 ----------
  final consIds = _collectIds(consMap);
  final vowIds = _collectIds(vowMap);

  final consDup = _collectDuplicateIds(consMap);
  final vowDup = _collectDuplicateIds(vowMap);

  if (consDup.isNotEmpty) {
    errors.add('자음: 중복 id 감지 → ${consDup.join(', ')}');
  }
  if (vowDup.isNotEmpty) {
    errors.add('모음: 중복 id 감지 → ${vowDup.join(', ')}');
  }

  // ---------- 자산 stem 수집(확장자 제거) + 확장자 경고 ----------
  final consDirScan = _scanDir(consDir);
  final vowelDirScan = _scanDir(vowelDir);

  // 확장자 경고
  for (final bad in consDirScan.unexpectedExtFiles) {
    warns.add('자음: 허용되지 않은 확장자 → $bad (허용: ${allowedExts.join(', ')})');
  }
  for (final bad in vowelDirScan.unexpectedExtFiles) {
    warns.add('모음: 허용되지 않은 확장자 → $bad (허용: ${allowedExts.join(', ')})');
  }

  final consStems = consDirScan.stems;
  final vowelStems = vowelDirScan.stems;

  // ---------- 누락 검사 (JSON → 자산) ----------
  for (final id in consIds) {
    if (!consStems.contains(id)) {
      errors.add('자음: 자산 누락 → $consDir/$id.(png|json)');
    }
  }
  for (final id in vowIds) {
    if (allowMissingVowelIds.contains(id)) continue; // 허용 누락
    if (!vowelStems.contains(id)) {
      errors.add('모음: 자산 누락 → $vowelDir/$id.(png|json)');
    }
  }

  // ---------- 고아 자산 검사 (자산 → JSON) ----------
  for (final stem in consStems.difference(consIds)) {
    warns.add('자음: JSON에 없음(고아 자산) → $consDir/$stem.(png|json)');
  }
  for (final stem in vowelStems.difference(vowIds)) {
    // 아래아를 파일로 준비해두셨다면 JSON에도 id가 있어 고아가 아니어야 정상.
    // 그래도 고의로 남겨둔 가이드가 있다면 경고로만 보고 끝냅니다.
    warns.add('모음: JSON에 없음(고아 자산) → $vowelDir/$stem.(png|json)');
  }

  // ---------- 결과 리포트 ----------
  print('=== Stroke Asset Verify ===');
  print('- JSON 자음 수: ${consIds.length}, 자산(stem) 수: ${consStems.length}');
  print('- JSON 모음 수: ${vowIds.length}, 자산(stem) 수: ${vowelStems.length}');
  if (allowMissingVowelIds.isNotEmpty) {
    print('- 누락 허용 모음 id: ${allowMissingVowelIds.join(', ')}');
  }
  print('');

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

  // ---------- 종료 코드 ----------
  if (errors.isNotEmpty) {
    exitCode = 1;
  } else if (strict && warns.isNotEmpty) {
    // --strict면 경고도 실패 처리
    exitCode = 1;
  } else {
    exitCode = 0;
  }
}

// JSON parts[*].chars[*].id 수집
Set<String> _collectIds(Map m) {
  final ids = <String>{};
  final parts = (m['parts'] ?? []) as List;
  for (final p in parts) {
    final chars = (p is Map ? (p['chars'] ?? []) : []) as List;
    for (final c in chars) {
      final id = '${(c as Map)['id'] ?? ''}'.trim();
      if (id.isNotEmpty) ids.add(id);
    }
  }
  return ids;
}

// 중복 id 찾기
Set<String> _collectDuplicateIds(Map m) {
  final seen = <String, int>{};
  final dups = <String>{};
  final parts = (m['parts'] ?? []) as List;
  for (final p in parts) {
    final chars = (p is Map ? (p['chars'] ?? []) : []) as List;
    for (final c in chars) {
      final id = '${(c as Map)['id'] ?? ''}'.trim();
      if (id.isEmpty) continue;
      final n = (seen[id] ?? 0) + 1;
      seen[id] = n;
      if (n > 1) dups.add(id);
    }
  }
  return dups;
}

// 디렉토리 스캔 결과 구조체
class _DirScan {
  _DirScan(this.stems, this.unexpectedExtFiles);
  final Set<String> stems; // 확장자 제거한 파일명 집합
  final List<String> unexpectedExtFiles; // 허용 확장자 외 파일들의 전체 경로
}

// 디렉토리에서 stem 집합 수집 + 허용되지 않은 확장자 목록 수집
_DirScan _scanDir(String dirPath) {
  final dir = Directory(dirPath);
  if (!dir.existsSync()) return _DirScan(<String>{}, <String>[]);

  final stems = <String>{};
  final bads = <String>[];
  for (final e in dir.listSync(recursive: false, followLinks: false)) {
    if (e is! File) continue;
    final path = e.path.replaceAll('\\', '/');
    final name = path.split('/').last;
    final dot = name.lastIndexOf('.');
    if (dot <= 0) continue;
    final stem = name.substring(0, dot);
    final ext = name.substring(dot + 1).toLowerCase();
    if (allowedExts.contains(ext)) {
      stems.add(stem);
    } else {
      bads.add(path);
    }
  }
  return _DirScan(stems, bads);
}
