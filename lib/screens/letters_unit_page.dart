// lib/screens/letters_unit_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';

import '../utils/asset_path.dart';
import '../i18n/ui_texts.dart';
import 'package:korean_writing_app_new/i18n/language_state.dart';

// ✅ 실제 배너 광고 위젯
import 'package:korean_writing_app_new/ads/banner_ad_widget.dart';

class LettersUnitPage extends StatefulWidget {
  const LettersUnitPage({
    super.key,
    this.title,
    this.indexAssetPath,
  });

  /// 일반 진입:
  /// Navigator.pushNamed(
  ///   context,
  ///   '/letters/unit',
  ///   arguments: 'assets/....json',
  /// );
  ///
  /// 또는
  /// Navigator.pushNamed(
  ///   context,
  ///   '/letters/unit',
  ///   arguments: {'title':'...', 'indexAssetPath':'assets/...json'},
  /// );
  final String? title;
  final String? indexAssetPath;

  /// 헬퍼
  static void open(BuildContext context, String indexRoute, {String? title}) {
    Navigator.pushNamed(
      context,
      '/letters/unit',
      arguments: {'title': title, 'indexAssetPath': indexRoute},
    );
  }

  @override
  State<LettersUnitPage> createState() => _LettersUnitPageState();
}

class _LettersUnitPageState extends State<LettersUnitPage> {
  /// 현재 인덱스(허브/세트) JSON 경로
  String? _indexRoute;

  /// 로드된 JSON
  Map<String, dynamic>? _json;
  Map<String, dynamic>? _overview; // overviewRef 또는 inline title/description

  /// 화면 상태
  bool _loading = true;
  String? _error;

  /// 카드(허브/세트) 목록
  List<Map<String, dynamic>> _parts = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_indexRoute == null) {
      final args = ModalRoute.of(context)?.settings.arguments;

      // 문자열 또는 맵 둘 다 허용
      if (args is String && args.trim().isNotEmpty) {
        _indexRoute = args.trim();
      } else if (args is Map) {
        final p = args['indexAssetPath'];
        if (p is String && p.trim().isNotEmpty) {
          _indexRoute = p.trim();
        }
      }

      // 최종 폴백
      _indexRoute ??= 'assets/data/letters/2_index.json';
      _loadIndex(_indexRoute!);
    }
  }

  // ───────────────────────────────────────────────────────────────
  // 데이터 로드
  Future<void> _loadIndex(String route) async {
    setState(() {
      _loading = true;
      _error = null;
      _overview = null;
      _parts = const [];
    });

    try {
      final resolved = AssetPath.resolve(route);
      final raw = await rootBundle.loadString(resolved);
      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Index JSON must be an object');
      }

      // 카드 목록 만들기
      final parts = _normalizeToCards(route, data);

      // overview 로드 (overviewRef > inline)
      Map<String, dynamic>? overview;
      final ref = data['overviewRef']?.toString();
      if (ref != null && ref.isNotEmpty) {
        try {
          final ovPath = AssetPath.resolve(ref);
          final ovRaw = await rootBundle.loadString(ovPath);
          final ov = jsonDecode(ovRaw);
          if (ov is Map<String, dynamic>) overview = ov;
        } catch (_) {
          // 개요 로드는 실패해도 치명적이지 않음
        }
      }
      overview ??= _inlineOverviewIfAny(data);

      if (!mounted) return;
      setState(() {
        _json = data;
        _parts = parts;
        _overview = overview;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '로드 실패: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<Map<String, dynamic>> _normalizeToCards(
      String selfRoute, Map<String, dynamic> data) {
    // ① 마스터 인덱스: categories → 유형 카드(2_1~2_4)
    if (data['categories'] is List) {
      return (data['categories'] as List)
          .whereType<Map>()
          .map<Map<String, dynamic>>((m0) {
        final m = Map<String, dynamic>.from(m0);
        return {
          'id': (m['id'] ?? '').toString(),
          'title': m['title'],
          'subtitle': m['subtitle'],
          'route': (m['route'] ?? '').toString(),
          'layout': 'category',
        };
      }).toList();
    }

    // ② 서브 허브: variants → (2_2, 2_4 등)
    if (data['variants'] is List) {
      return (data['variants'] as List)
          .whereType<Map>()
          .map<Map<String, dynamic>>((m0) {
        final m = Map<String, dynamic>.from(m0);
        return {
          'id': (m['key'] ?? m['id'] ?? '').toString(),
          'title': m['title'],
          'subtitle': m['subtitle'],
          'route': (m['route'] ?? '').toString(),
          'layout': 'variant',
        };
      }).toList();
    }

    // ③ 기존 parts 배열 그대로
    if (data['parts'] is List) {
      return (data['parts'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    // ④ 리프 세트(JSON이 items/sequence/glyphs만 갖는 경우) → "이 세트" 1장 카드
    if (data['items'] is List ||
        data['sequence'] is List ||
        data['glyphs'] is List) {
      return [
        {
          'id': (data['unitId'] ?? data['id'] ?? 'set').toString(),
          'title': data['title'],
          'subtitle': data['subtitle'],
          'route': selfRoute,
          'layout': 'set',
        }
      ];
    }

    // 그 외 → 빈 목록
    return const [];
  }

  Map<String, dynamic>? _inlineOverviewIfAny(Map<String, dynamic> data) {
    final t = data['title'];
    final d = data['description'] ?? data['desc'];
    final hasTitle =
        t is Map && t.isNotEmpty || t is String && t.trim().isNotEmpty;
    final hasDesc =
        d is Map && d.isNotEmpty || d is String && d.trim().isNotEmpty;
    if (!hasTitle && !hasDesc) return null;

    return {
      'id': data['id'] ?? 'overview_inline',
      'type': 'overview',
      if (hasTitle) 'title': t,
      if (hasDesc) 'description': d,
    };
  }

  // 리프 세트에서 글자 추출: sequence > glyphs > items[].glyph
  List<String> _extractGlyphs(dynamic data) {
    final out = <String>[];

    if (data is Map<String, dynamic>) {
      final seq = data['sequence'];
      if (seq is List) {
        for (final v in seq) {
          final s = v?.toString() ?? '';
          if (s.isNotEmpty) out.add(s);
        }
      }
      final gl = data['glyphs'];
      if (gl is List) {
        for (final v in gl) {
          final s = v?.toString() ?? '';
          if (s.isNotEmpty) out.add(s);
        }
      }
      final items = data['items'];
      if (items is List) {
        for (final it in items) {
          if (it is Map && it['glyph'] != null) {
            final s = it['glyph'].toString();
            if (s.isNotEmpty) out.add(s);
          }
        }
      }
    }
    return out.toSet().toList(); // 중복 제거
  }

  // 허브/세트 카드 탭 핸들링: 허브면 재귀 진입, 리프면 연습 바텀시트
  void _openPart(Map<String, dynamic> p) async {
    final route = (p['route'] ?? '').toString();
    final layout = (p['layout'] ?? '').toString();
    if (route.isEmpty) return;

    // 허브(카테고리/분기)
    if (layout == 'category' || layout == 'variant') {
      if (!mounted) return;
      Navigator.pushNamed(context, '/letters/unit', arguments: route);
      return;
    }

    // 리프 세트: 글자 배열 읽어서 “쓰기 연습” 바텀시트 → /write
    try {
      final resolved = AssetPath.resolve(route);
      final raw = await rootBundle.loadString(resolved);
      final data = jsonDecode(raw);

      final glyphs = _extractGlyphs(data);
      if (glyphs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(UiText.t('noItems'))));
        return;
      }

      final title = (p['title']?['ko'] ?? p['title']?['en'] ?? p['title'] ?? '')
          .toString();
      final chosen = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (_) => _GlyphPickerSheet(
          title: title.isEmpty ? UiText.t('practice') : title,
          glyphs: glyphs,
        ),
      );
      if (chosen == null || chosen.isEmpty) return;

      if (!mounted) return;
      Navigator.pushNamed(context, '/write', arguments: chosen);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${UiText.t("failed")}: $e')),
      );
    }
  }

  // 현재 언어(ko-*, en 우선)에서 텍스트 꺼내기
  String? _pickI18n(dynamic value) {
    if (value is String) return value;
    if (value is Map) {
      final code = LanguageState.I.code.toLowerCase();
      final base = code.split('-').first;
      final s = value[code] ?? value[base] ?? value['ko'] ?? value['en'];
      return s?.toString();
    }
    return null;
  }

  // ───────────────────────────────────────────────────────────────
  // UI
  @override
  Widget build(BuildContext context) {
    final title = widget.title ??
        (_pickI18n(_json?['title'])?.trim().isNotEmpty == true
            ? _pickI18n(_json?['title'])!
            : 'Letters Unit');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          // 개요 다이얼로그 (있을 때만)
          IconButton(
            tooltip: UiText.t('overview'),
            onPressed: _overview == null ? null : _showOverviewDialog,
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null
          ? Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red),
        ),
      )
          : _buildBody()),
      // ─────────────────────────────
      // 하단 배너 광고 – 실제 BannerAdArea 사용
      // ─────────────────────────────
      bottomNavigationBar: const SafeArea(
        top: false,
        child: BannerAdArea(),
      ),
    );
  }

  Widget _buildBody() {
    final parts = _parts;
    if (parts.isEmpty) {
      return Center(child: Text(UiText.t('noItems')));
    }

    final width = MediaQuery.of(context).size.width;
    int cross = 2;
    if (width >= 1200) {
      cross = 5;
    } else if (width >= 900) {
      cross = 4;
    } else if (width >= 600) {
      cross = 3;
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: parts.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cross,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.22,
      ),
      itemBuilder: (_, i) {
        final p = parts[i];
        return _PartCard.fromJson(
          p,
          onTap: () => _openPart(p), // 카드 전체 탭 = 허브면 열기, 리프면 “쓰기 연습”
        );
      },
    );
  }

  void _showOverviewDialog() {
    final t = _pickI18n(_overview?['title']) ?? UiText.t('overview');
    final d = _pickI18n(_overview?['description']) ?? '';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t),
        content: d.isEmpty ? Text(UiText.t('noItems')) : Text(d),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(UiText.t('ok')),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────
// 카드 (허브/리프 공용)
class _PartCard extends StatelessWidget {
  const _PartCard({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.layout,
    required this.onTap,
  });

  factory _PartCard.fromJson(
      Map<String, dynamic> p, {
        required VoidCallback onTap,
      }) {
    return _PartCard(
      id: (p['id'] ?? '').toString(),
      title: (p['title']?['ko'] ?? p['title']?['en'] ?? p['title'] ?? '')
          .toString(),
      subtitle:
      (p['subtitle']?['ko'] ?? p['subtitle']?['en'] ?? '').toString(),
      route: (p['route'] ?? '').toString(),
      layout: (p['layout'] ?? p['type'] ?? '').toString(),
      onTap: onTap,
    );
  }

  final String id;
  final String title;
  final String subtitle;
  final String route;
  final String layout;
  final VoidCallback onTap;

  bool get _isHub => layout == 'category' || layout == 'variant';

  @override
  Widget build(BuildContext context) {
    final disabled = route.isEmpty;
    return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: disabled ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // 헤더 (넘버링)
              Row(
              children: [
              CircleAvatar(
              radius: 18,
                child: Text(
                  id.split('_').last,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title.isNotEmpty ? title : '(untitled)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ],
            ),

            // 부제 (있으면만)
            if (subtitle.trim().isNotEmpty) ...[
    const SizedBox(height: 6),
    Text(
    subtitle,
    style:
    const TextStyle(fontSize: 13, color: Colors.black54),
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    ),
    ],

    const Spacer(),
    const Divider(height: 16),

    // 허브면 “열기”, 리프면 “쓰기 연습”
    Align(
    alignment: Alignment.centerLeft,
    child: _isHub
    ? FilledButton.icon(
    onPressed: disabled ? null : onTap,
    icon: const Icon(Icons.play_arrow),
    label: Text(UiText.t('open')),
    )
        : OutlinedButton.icon(
    onPressed: disabled ? null : onTap,
    icon: const Icon(Icons.create),
    label: Text(UiText.t('practice')),
    ),
    ),
    ],
    ),
    ),
    ),
    );
  }
}

// ───────────────────────────────────────────────────────────────
// 글자 선택 바텀시트 (아이콘/음성 미리듣기 제거)
class _GlyphPickerSheet extends StatelessWidget {
  const _GlyphPickerSheet({
    required this.title,
    required this.glyphs,
  });

  final String title;
  final List<String> glyphs;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$title — ${UiText.t('practice')}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final g in glyphs)
                    GestureDetector(
                      onTap: () => Navigator.pop(context, g), // 탭: 선택
                      child: Chip(
                        label: Text(
                          g,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(UiText.t('cancel')),
            ),
          ],
        ),
      ),
    );
  }
}
