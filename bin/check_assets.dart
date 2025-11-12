// bin/check_assets.dart
import 'dart:convert';
import 'dart:io';

/// pubspec.yaml의 assets 항목에 등록된 경로가 실제 존재하는지 점검.
/// 누락 시 ❌, 존재 시 ✅ 표시.
/// 결과는 콘솔 출력 및 logs/assets_check.txt로 저장 가능.
void main() {
  final file = File('pubspec.yaml');
  if (!file.existsSync()) {
    stderr.writeln('pubspec.yaml not found');
    exit(1);
  }

  final yaml = file.readAsStringSync();
  final lines = const LineSplitter().convert(yaml);

  final roots = <String>[];
  var inAssets = false;

  for (final l in lines) {
    if (l.trim() == 'assets:') {
      inAssets = true;
      continue;
    }
    if (inAssets && RegExp(r'^\S').hasMatch(l)) {
      // 들여쓰기 없이 시작 → assets 블록 종료
      break;
    }
    if (inAssets) {
      final m = RegExp(r'^\s*-\s*(.+)$').firstMatch(l);
      if (m != null) {
        roots.add(m.group(1)!.trim());
      }
    }
  }

  print('🔍 Checking ${roots.length} asset paths...\n');

  var missing = 0;
  for (final path in roots) {
    final dirExists = Directory(path).existsSync();
    final fileExists = File(path).existsSync();

    if (!dirExists && !fileExists) {
      print('❌ Missing: $path');
      missing++;
    } else {
      print('✅ Exists: $path');
    }
  }

  if (missing > 0) {
    print('\n⚠️  $missing asset path(s) missing!');
    exitCode = 2;
  } else {
    print('\n✅ All assets verified.');
  }
}
