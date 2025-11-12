// lib/screens/letters_category_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:korean_writing_app_new/i18n/ui_texts.dart';
import 'package:korean_writing_app_new/i18n/language_state.dart';
import 'package:korean_writing_app_new/screens/writing_practice_page.dart';

class LettersCategoryPage extends StatefulWidget {
  const LettersCategoryPage({
    super.key,
    required this.title,
    this.overviewRef,
    this.indexAssetPath,
    this.sectionId,
  });

  final String title; // AppBar 표시는 무조건 이 값 사용
  final String? overviewRef; // 개요 JSON 경로(선택)
  final String? indexAssetPath; // 인덱스/세트 JSON 경로
  final String? sectionId; // "2_1" 등 (선택)

  @override
  State<LettersCategoryPage> createState() => _LettersCategoryPageState();
}

class _LettersCategoryPageState extends State<LettersCategoryPage> {
  Map<String, dynamic>? _indexJson; // 현재 로드한 JSON (허브/세트)
  Map<String, dynamic>? _overviewJson; // 개요 JSON
  String? _error;
  bool _loading = true;

  // 언어 변경시 리빌드용
  VoidCallback? _langListener;

  // 연습 세트 시퀀스 캐시(같은 카드에서 재사용)
  final Map<String, List<String>> _seqCache = {};

  @override
  void initState() {
    super.initState();
    _loadBundle();

    // 언어 변경 시 화면 즉시 갱신 (안정성: try-catch 불필요)
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

  // ─────────────────────── Data Load ───────────────────────
  Future<void> _loadBundle() async {
    final path = widget.indexAssetPath;
    if (path == null || path.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'indexAssetPath not provided';
      });
      return;
    }

    try {
      final raw = await rootBundle.loadString(path);
      final j = jsonDecode(raw);
      if (j is! Map<String, dynamic>) {
        throw const FormatException('Index JSON is not an object');
      }

      // overviewRef 우선순위: 위젯 인자 > 인덱스 JSON 내부 키
      String? overviewRef = widget.overviewRef;
      if ((overviewRef == null || overviewRef.isEmpty) &&
          j['overviewRef'] is String &&
          (j['overviewRef'] as String).trim().isNotEmpty) {
        overviewRef = (j['overviewRef'] as String).trim();
      }

      Map<String, dynamic>? overview;
      if (overviewRef != null && overviewRef.isNotEmpty) {
        try {
          final ovRaw = await rootBundle.loadString(overviewRef);
          final ov = jsonDecode(ovRaw);
          if (ov is Map<String, dynamic>) {
            overview = ov;
          }
        } catch (_) {
          // 개요 로드 실패는 무시 (안정성)
        }
      }

      if (!mounted) return;
      setState(() {
        _indexJson = j;
        _overviewJson = overview;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Load fail: ${widget.indexAssetPath}\n$e';
      });
      // ignore: avoid_print
      print('[LettersCategoryPage] $_error');
    }
  }

  // ─────────────────────── Helpers ───────────────────────
  String _t(String key, String fallback) {
    try {
      final s = UiText.t(key);
      if (s.trim().isNotEmpty) return s;
    } catch (_) {}
    return fallback;
  }

  String _pickI18n(Map? m, {String fallback = ''}) {
    if (m == null) return fallback;
    final code = LanguageState.I.code.split('-').first;
    final s = (m[code] ?? m['ko'] ?? m['en'] ?? '')?.toString() ?? '';
    if (s.trim().isNotEmpty) return s;
    if (m.isNotEmpty) {
      final any = m.values.first?.toString() ?? '';
      if (any.trim().isNotEmpty) return any;
    }
    return fallback;
  }

  String? _localizedFromMap(Map? m) {
    if (m == null) return null;
    final code = LanguageState.I.code.split('-').first;
    return (m[code] as String?) ??
        (m['ko'] as String?) ??
        (m['en'] as String?) ??
        m.values.first?.toString();
  }

  bool _isLeaf(Map<String, dynamic> j) {
    final v = (j['variants'] as List?) ?? const [];
    final it = (j['items'] as List?) ?? const [];
    final cards = (j['cards'] as List?) ?? const [];
    return v.isEmpty && it.isEmpty && cards.isEmpty;
  }

  String? _overviewDesc(Map<String, dynamic> index, Map<String, dynamic>? ov) {
    for (final src in [ov, index]) {
      if (src == null) continue;
      for (final k in ['desc', 'description', 'body', 'content', 'overview']) {
        final v = src[k];
        if (v is Map) {
          final picked = _pickI18n(v);
          if (picked.trim().isNotEmpty) return picked;
        } else if (v is String && v.trim().isNotEmpty) {
          return v;
        }
      }
    }
    return null;
  }

  // 주어진 에셋 JSON이 허브(=items/variants 존재)인지, 세트(leaf)인지 판별
  Future<bool> _isIndexJson(String assetPath) async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final j = jsonDecode(raw);
      if (j is! Map<String, dynamic>) return false;
      final items = (j['items'] as List?) ?? const [];
      final variants = (j['variants'] as List?) ?? const [];
      final cards = (j['cards'] as List?) ?? const [];
      return items.isNotEmpty || variants.isNotEmpty || cards.isNotEmpty;
    } catch (_) {
      return false; // 로드 실패 → 세트로 간주하여 유닛으로 보냄
    }
  }

  // 캐시 사용 버전(같은 카드 재진입 시 재로딩 방지)
  Future<List<String>> _getSequenceCached(String route,
      {String key = 'sequence'}) async {
    final cacheKey = '$route::$key';
    final cached = _seqCache[cacheKey];
    if (cached != null && cached.isNotEmpty) return cached;

    final raw = await rootBundle.loadString(route);
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final list =
        (map[key] as List).map((e) => e.toString()).toList(growable: false);

    _seqCache[cacheKey] = list;
    return list;
  }

  // 글자 선택 바텀시트 (가독성/클릭영역 강화)
  Future<String?> _showSyllablePickerBottomSheet({
    required BuildContext context,
    required String title,
    required List<String> syllables,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.85,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: LayoutBuilder(
                builder: (ctx, c) {
                  final w = c.maxWidth;
                  final btnFont = (w / 28).clamp(16.0, 22.0);
                  final btnHPad = (w / 40).clamp(14.0, 22.0);
                  final btnVPad = (w / 80).clamp(10.0, 16.0);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints:
                                BoxConstraints(maxWidth: w.clamp(480.0, 920.0)),
                            child: Scrollbar(
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: syllables.map((s) {
                                    return OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: btnHPad,
                                          vertical: btnVPad,
                                        ),
                                        side: BorderSide(
                                          color: Theme.of(ctx)
                                              .colorScheme
                                              .outline
                                              .withValues(alpha: .6),
                                        ),
                                        textStyle: TextStyle(
                                          fontSize: btnFont,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(22),
                                        ),
                                      ),
                                      onPressed: () => Navigator.pop(ctx, s),
                                      child: Text(s),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(UiText.t('cancel').isNotEmpty
                            ? UiText.t('cancel')
                            : '취소'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────── UI ───────────────────────
  @override
  Widget build(BuildContext context) {
    // AppBar 제목은 **항상** 위젯 인자만 사용 (개요 JSON의 title 미사용)
    final appBarTitle =
        (widget.title.isNotEmpty ? widget.title : _t('letters', '글자'));

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          if (widget.sectionId != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  widget.sectionId!,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _errorView(context, _error!);
    if (_indexJson == null || _indexJson!.isEmpty) {
      return _emptyView(context, '인덱스 데이터가 비어 있습니다.');
    }

    final J = _indexJson!;
    final isLeaf = _isLeaf(J);
    final isSubhub = (J['type']?.toString() == 'subhub');

    // 개요 설명만 사용 (제목은 숨김)
    final headerDesc = _overviewDesc(J, _overviewJson) ?? '';

    final variants = (J['variants'] as List?) ?? const [];
    final items = (J['items'] as List?) ?? const [];
    final cards = (J['cards'] as List?) ?? const [];

    // leaf(세트)면 자동으로 유닛 화면으로 보낸다.
    if (isLeaf) {
      final datasetRoute = widget.indexAssetPath ?? '';
      if (datasetRoute.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.pushNamed(context, '/letters/unit',
              arguments: datasetRoute);
        });
      }
      return const Center(child: CircularProgressIndicator());
    }

    // 허브(목록) 렌더링
    return Column(
      children: [
        if (headerDesc.trim().isNotEmpty)
          _overviewSection(context, /*hide title*/ '', headerDesc),
        Expanded(
          child: Builder(builder: (context) {
            // 1) 분기형(2.2/2.4)
            if (isSubhub && variants.isNotEmpty) {
              final uiCards = variants.map((v0) {
                final v = (v0 as Map?)?.cast<String, dynamic>() ??
                    <String, dynamic>{};
                final t = (v['title'] is Map)
                    ? _pickI18n(v['title'] as Map, fallback: 'Variant')
                    : (v['title']?.toString() ?? 'Variant');
                final route = (v['route'] ?? '').toString();
                final sub =
                    J['subtitle'] is Map ? _pickI18n(J['subtitle'] as Map) : '';
                return _ItemCard(
                  title: t,
                  subtitle: sub,
                  route: route,
                  onTap: () => _openNext(context, t, route),
                );
              }).toList();
              return _gridList(context, uiCards);
            }

            // 2) 단일형(2.1/2.3)
            final List<_ItemCard> uiCards = [];

            for (final it0 in items) {
              final it =
                  (it0 as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
              final t = (it['title'] is Map)
                  ? _pickI18n(it['title'] as Map, fallback: 'Untitled')
                  : (it['title']?.toString() ?? 'Untitled');
              final route = (it['route'] ?? '').toString();
              final sub = (it['subtitle'] ?? '').toString();

              uiCards.add(_ItemCard(
                title: t,
                subtitle: sub,
                route: route,
                onTap: () => _openPracticeOrNext(context,
                    title: t, route: route, item: it),
              ));
            }

            for (final c0 in cards) {
              final c =
                  (c0 as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
              final t = (c['title'] is Map)
                  ? _pickI18n(c['title'] as Map, fallback: 'Untitled')
                  : (c['title']?.toString() ?? 'Untitled');
              final idx = (c['indexAsset'] ?? '').toString();
              final sub = (c['subtitle'] ?? '').toString();

              uiCards.add(_ItemCard(
                title: t,
                subtitle: sub,
                route: idx,
                onTap: () =>
                    _openPracticeOrNext(context, title: t, route: idx, item: c),
              ));
            }

            if (uiCards.isEmpty) {
              return _emptyView(context, '표시할 항목이 없습니다.');
            }
            return _gridList(context, uiCards);
          }),
        ),
      ],
    );
  }

  // directPractice가 설정된 경우: 곧바로 글자 선택 → 연습 화면
  Future<void> _openPracticeOrNext(
    BuildContext context, {
    required String title,
    required String route,
    required Map<String, dynamic> item,
  }) async {
    final bool directPractice = (item['directPractice'] == true);
    final Map<String, dynamic>? practiceSource = (item['practiceSource'] is Map)
        ? (item['practiceSource'] as Map).cast<String, dynamic>()
        : null;

    if (directPractice && practiceSource != null) {
      final practiceSetRoute = (practiceSource['route'] ?? '').toString();
      final key = (practiceSource['key'] ?? 'sequence').toString();

      if (practiceSetRoute.isEmpty) {
        _showSnack(context, '연습 세트 경로가 없습니다.');
        return;
      }

      try {
        final seq = await _getSequenceCached(practiceSetRoute, key: key);
        if (seq.isEmpty) {
          _showSnack(context, '연습할 글자가 없습니다.');
          return;
        }

        final pickerTitle =
            _localizedFromMap(item['practicePickerTitle']) ?? '쓰기 연습';

        // 사용자가 '취소'를 누를 때까지 반복해서 바텀시트를 띄움
        while (mounted) {
          final selected = await _showSyllablePickerBottomSheet(
            context: context,
            title: pickerTitle,
            syllables: seq,
          );
          if (selected == null) break; // 취소

          await Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => WritingPracticePage(charGlyph: selected)),
          );
          // 돌아오면 루프가 계속되어 바텀시트 재오픈
        }
        return;
      } catch (e) {
        _showSnack(context, '연습 데이터를 불러오지 못했습니다.');
        // ignore: avoid_print
        print('[LettersCategoryPage] directPractice error: $e');
        return;
      }
    }

    // directPractice가 아니면 기존 로직으로 분기
    await _openNext(context, title, route);
  }

  /// route가 에셋 JSON일 때, 그 JSON을 잠깐 읽어
  /// - 허브(=items/variants 존재)면 카테고리로 push
  /// - 세트(leaf)면 바로 /letters/unit 로 이동
  Future<void> _openNext(
      BuildContext context, String title, String route) async {
    if (route.isEmpty) {
      _showSnack(context, '경로가 비어 있습니다.');
      return;
    }
    final isAssetPath = route.startsWith('assets/');
    final isJson = route.toLowerCase().endsWith('.json');

    if (isAssetPath && isJson) {
      final looksLikeIndex = await _isIndexJson(route);
      if (!mounted) return;

      if (looksLikeIndex) {
        // 인덱스/허브: 같은 페이지를 재귀 진입
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LettersCategoryPage(
              title: title,
              indexAssetPath: route,
              sectionId: widget.sectionId,
            ),
          ),
        );
      } else {
        // 세트(leaf): 문자열 경로만 전달
        Navigator.pushNamed(context, '/letters/unit', arguments: route);
      }
      return;
    }

    if (isAssetPath && !isJson) {
      // 확장자 생략된 에셋 경로면 .json 붙여서 동일 판별
      final jsonPath = '$route.json';
      final looksLikeIndex = await _isIndexJson(jsonPath);
      if (!mounted) return;

      if (looksLikeIndex) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LettersCategoryPage(
              title: title,
              indexAssetPath: jsonPath,
              sectionId: widget.sectionId,
            ),
          ),
        );
      } else {
        Navigator.pushNamed(context, '/letters/unit', arguments: jsonPath);
      }
      return;
    }

    // 그 외는 앱 라우트로 시도
    Navigator.pushNamed(context, route, arguments: {'title': title});
  }

  // ─────────────────────── UI pieces ───────────────────────
  Widget _overviewSection(BuildContext context, String t, String d) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (t.trim().isNotEmpty)
            Text(
              t,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          if (d.trim().isNotEmpty) const SizedBox(height: 6),
          if (d.trim().isNotEmpty)
            Text(
              d,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                height: 1.4,
                color: Colors.black.withValues(alpha: .75),
              ),
            ),
        ],
      ),
    );
  }

  Widget _gridList(BuildContext context, List<_ItemCard> cards) {
    return LayoutBuilder(builder: (ctx, c) {
      final w = c.maxWidth;
      int col = 1;
      if (w >= 1200) {
        col = 4;
      } else if (w >= 900)
        col = 3;
      else if (w >= 600) col = 2;
      return GridView.count(
        crossAxisCount: col,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        padding: const EdgeInsets.all(16),
        childAspectRatio: 16 / 10,
        children: cards,
      );
    });
  }

  Widget _errorView(BuildContext context, String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          '오류가 발생했습니다.\n$msg',
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _emptyView(BuildContext context, String msg) {
    return Center(
      child: Text(
        msg,
        style: Theme.of(context).textTheme.bodyLarge,
        textAlign: TextAlign.center,
      ),
    );
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.title,
    required this.subtitle,
    required this.route,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = route.isEmpty;
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: disabled ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.isEmpty ? '제목 없음' : title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              if (subtitle.trim().isNotEmpty)
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: .65),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              Row(
                children: [
                  const Spacer(),
                  Icon(
                    disabled ? Icons.block : Icons.arrow_forward_rounded,
                    size: 20,
                    color: disabled
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
