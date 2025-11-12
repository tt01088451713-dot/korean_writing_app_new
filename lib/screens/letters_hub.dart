// lib/screens/letters_hub.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:korean_writing_app_new/i18n/ui_texts.dart';
import 'package:korean_writing_app_new/i18n/language_state.dart';
import 'letters_category_page.dart';

/// 개요/인덱스(JSON) 기본 경로
const _kOverviewPath = 'assets/data/letters/overviews/2_0_overview.json';
const _kIndexPath = 'assets/data/letters/2_index.json';

class LettersHubPage extends StatefulWidget {
  const LettersHubPage({super.key});
  @override
  State<LettersHubPage> createState() => _LettersHubPageState();
}

class _LettersHubPageState extends State<LettersHubPage> {
  Map<String, dynamic>? _overview;
  List<Map<String, dynamic>> _categories = const [];
  String? _error;
  bool _loading = true;

  VoidCallback? _langListener; // 언어 변경 즉시 리빌드

  @override
  void initState() {
    super.initState();
    _loadOverviewAndCategories();
    _langListener = () => setState(() {});
    LanguageState.I.addListener(_langListener!);
  }

  @override
  void dispose() {
    if (_langListener != null) {
      LanguageState.I.removeListener(_langListener!);
    }
    super.dispose();
  }

  Future<void> _loadOverviewAndCategories() async {
    setState(() {
      _loading = true;
      _error = null;
      _overview = null;
      _categories = const [];
    });

    // 1) 개요(선택)
    try {
      final overviewRaw = await rootBundle.loadString(_kOverviewPath);
      final ov = jsonDecode(overviewRaw);
      if (ov is Map<String, dynamic>) _overview = ov;
    } catch (_) {
      // 개요는 선택이므로 실패 무시
    }

    // 2) 인덱스(필수)
    try {
      final indexRaw = await rootBundle.loadString(_kIndexPath);
      final idx = jsonDecode(indexRaw);
      if (idx is! Map<String, dynamic>) {
        throw const FormatException('2_index.json must be a JSON object.');
      }
      final cats = (idx['categories'] as List?) ?? const [];
      _categories = cats
          .whereType<Map>()
          .map((m) => m.cast<String, dynamic>())
          .toList(growable: false);

      // 안전 폴백
      if (_categories.isEmpty) {
        _categories = [
          {
            'id': '2_1',
            'title': {'ko': '좌우 결합형', 'en': 'Left–Right Blocks'},
            'route': 'assets/data/letters/2_1_left_right_index.json',
            'overviewRef': 'assets/data/letters/overviews/2_1_overview.json',
          },
          {
            'id': '2_2',
            'title': {'ko': '상하 결합형', 'en': 'Top–Bottom Blocks'},
            'route': 'assets/data/letters/2_2_hub_index.json',
            'overviewRef': 'assets/data/letters/overviews/2_2_overview.json',
          },
          {
            'id': '2_3',
            'title': {'ko': '좌우상하 결합형', 'en': 'Left–Right + Top–Bottom'},
            'route': 'assets/data/letters/2_3_hub_index.json',
            'overviewRef': 'assets/data/letters/overviews/2_3_overview.json',
          },
          {
            'id': '2_4',
            'title': {'ko': 'ㅡ형', 'en': 'Horizontal Pattern (ㅡ)'},
            'route': 'assets/data/letters/2_4_hub_index.json',
            'overviewRef': 'assets/data/letters/overviews/2_4_overview.json',
          },
        ];
      }

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '글자 인덱스 로드 실패: $_kIndexPath\n$e';
        _loading = false;
      });
    }
  }

  /// 다국어 맵에서 현재 언어 우선으로 텍스트 선택
  String _pickLang(dynamic v) {
    if (v is String) return v;
    if (v is Map) {
      final code = LanguageState.I.code.toLowerCase();
      final base = code.split('-').first;
      final cur = (v[code] ?? '').toString();
      if (cur.trim().isNotEmpty) return cur;
      final curBase = (v[base] ?? '').toString();
      if (curBase.trim().isNotEmpty) return curBase;
      final en = (v['en'] ?? '').toString();
      if (en.trim().isNotEmpty) return en;
      final ko = (v['ko'] ?? '').toString();
      if (ko.trim().isNotEmpty) return ko;
      if (v.isNotEmpty) {
        final any = (v.values.first ?? '').toString();
        if (any.trim().isNotEmpty) return any;
      }
    }
    return v?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 안전 가드 추가: 키 그대로("letters")면 폴백
    final t = UiText.t('letters').trim();
    final appBarTitle = (t.isNotEmpty && t != 'letters') ? t : '글자';

    // ✅ 개요는 설명만 사용(제목은 숨김)
    final String desc = _pickLang(_overview?['description']);

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: _error != null
          ? _errorView(_error!)
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_overview != null && desc.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          desc,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 15,
                            height: 1.4,
                            color: Colors.black.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    Expanded(child: _gridCategories(context)),
                  ],
                ),
    );
  }

  Widget _gridCategories(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final w = c.maxWidth;
      int col = 1;
      if (w >= 1200) {
        col = 4;
      } else if (w >= 900)
        col = 3;
      else if (w >= 600) col = 2;

      // 반응형 라벨 크기
      final scale = w / 400;
      final labelFontSize = (16 * scale.clamp(1.0, 1.4));

      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: col,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 16 / 10,
        ),
        itemCount: _categories.length,
        itemBuilder: (_, i) =>
            _buildCategoryCard(context, _categories[i], labelFontSize),
      );
    });
  }

  Widget _buildCategoryCard(
    BuildContext context,
    Map<String, dynamic> cat,
    double labelFontSize,
  ) {
    final catTitle = _pickLang(cat['title']);
    final routePath = (cat['route'] ?? '').toString();
    final overviewRef = (cat['overviewRef'] ?? '').toString();
    final sectionId = (cat['id'] ?? '').toString();
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openCategory(catTitle, sectionId, routePath, overviewRef),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                catTitle.isEmpty ? 'Untitled' : catTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCategory(
    String title,
    String sectionId,
    String routePath,
    String? overviewRef,
  ) {
    if (routePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카테고리 경로가 비었습니다.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LettersCategoryPage(
          title: title,
          indexAssetPath: routePath,
          overviewRef: (overviewRef ?? '').isNotEmpty ? overviewRef : null,
          sectionId: sectionId,
        ),
      ),
    );
  }

  Widget _errorView(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          msg,
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
