// lib/screens/json_test_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show rootBundle, Clipboard, ClipboardData;

import 'package:korean_writing_app_new/i18n/ui_texts.dart';

class JsonTestPage extends StatefulWidget {
  const JsonTestPage({super.key, this.initialAssetPath});

  final String? initialAssetPath;

  @override
  State<JsonTestPage> createState() => _JsonTestPageState();
}

class _JsonTestPageState extends State<JsonTestPage> {
  final TextEditingController _pathCtrl = TextEditingController();

  List<dynamic> _rawItems = const [];
  List<dynamic> _viewItems = const [];

  String _search = '';
  bool _shuffle = false;
  int _limit = 1000000;

  // 초성 필터
  String _initialFilter = 'ALL';
  Set<String> _initialSet = {};

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pathCtrl.text =
        widget.initialAssetPath ?? 'assets/data/letters/2_1_1_basic.json';
    _load();
  }

  @override
  void dispose() {
    _pathCtrl.dispose();
    super.dispose();
  }

  // ────────────────────────────────────────────────────────────────
  // 로딩 & 가공
  // ────────────────────────────────────────────────────────────────
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _initialFilter = 'ALL';
      _initialSet.clear();
    });
    try {
      final raw = await rootBundle.loadString(_pathCtrl.text.trim());
      final parsed = jsonDecode(raw);

      List<dynamic> items;
      if (parsed is List) {
        items = parsed;
      } else if (parsed is Map<String, dynamic>) {
        final v = parsed['items'];
        if (v is List) {
          items = v;
        } else {
          items = [parsed];
        }
      } else {
        items = [parsed];
      }

      // 초성 수집(있을 때만)
      final set = <String>{};
      for (final e in items) {
        final ini = _extractInitial(e);
        if (ini != null && ini.isNotEmpty) set.add(ini);
      }

      _rawItems = items;
      _initialSet = set;
      _applyView();
    } catch (e) {
      _error = e.toString();
      _rawItems = const [];
      _viewItems = const [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyView() {
    List<dynamic> items = List<dynamic>.from(_rawItems);

    // 검색
    if (_search.trim().isNotEmpty) {
      final q = _search.trim();
      items = items.where((e) => _displayText(e).contains(q)).toList();
    }

    // 초성 필터
    if (_initialFilter != 'ALL') {
      items = items.where((e) => _extractInitial(e) == _initialFilter).toList();
    }

    // 섞기
    if (_shuffle) items.shuffle();

    // 제한
    if (_limit < items.length) items = items.sublist(0, _limit);

    setState(() => _viewItems = items);
  }

  // 표시 텍스트
  String _displayText(dynamic item) {
    if (item is String) return item;
    if (item is num) return item.toString();
    if (item is Map<String, dynamic>) {
      String? pick(dynamic v) {
        if (v is String) return v;
        if (v is Map) {
          if (v['ko'] is String && (v['ko'] as String).isNotEmpty) {
            return v['ko'];
          }
          if (v['en'] is String && (v['en'] as String).isNotEmpty) {
            return v['en'];
          }
          if (v.values.isNotEmpty && v.values.first is String) {
            return v.values.first as String;
          }
        }
        return null;
      }

      for (final k in ['glyph', 'char', 'title', 'syllable', 'label']) {
        if (item.containsKey(k)) {
          final v = item[k];
          final s = pick(v) ?? (v is String ? v : null);
          if (s != null && s.isNotEmpty) return s;
        }
      }
      return item.toString();
    }
    return item.toString();
  }

  // 쓰기 연습용 글자
  String? _extractGlyph(dynamic item) {
    if (item is String) return item;
    if (item is Map<String, dynamic>) {
      for (final k in ['glyph', 'char', 'syllable', 'letter']) {
        final v = item[k];
        if (v is String && v.isNotEmpty) return v;
      }
    }
    return null;
  }

  // 초성
  String? _extractInitial(dynamic item) {
    if (item is Map<String, dynamic>) {
      final v = item['initial'];
      if (v is String && v.isNotEmpty) return v;
    }
    return null;
  }

  // CSV 내보내기(보이는 목록만)
  Future<void> _exportCsv() async {
    final rows = <List<String>>[];
    rows.add(['index', 'glyph', 'title', 'initial']);
    for (var i = 0; i < _viewItems.length; i++) {
      final it = _viewItems[i];
      rows.add([
        '${i + 1}',
        _extractGlyph(it) ?? '',
        _displayText(it),
        _extractInitial(it) ?? '',
      ]);
    }
    final csv = rows.map((r) {
      return r.map((c) => '"${c.replaceAll('"', '""')}"').join(',');
    }).join('\n');

    await Clipboard.setData(ClipboardData(text: csv));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('${UiText.t('exportCsv')} — ${UiText.t('copied')}')),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // UI
  // ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(UiText.t('jsonTestPage')),
        actions: [
          IconButton(
            tooltip: UiText.t('exportCsv'),
            onPressed: _viewItems.isEmpty ? null : _exportCsv,
            icon: const Icon(Icons.table_view),
          ),
          IconButton(
            tooltip: UiText.t('reload'),
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTopControls(),
          const Divider(height: 1),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Expanded(
              child: Center(
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            )
          else
            Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildTopControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        children: [
          // 경로 입력
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pathCtrl,
                  decoration: InputDecoration(
                    labelText: UiText.t('typeAssetPath'),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _load(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.folder_open),
                label: Text(UiText.t('pickAsset')),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 검색
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: UiText.t('search'),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) {
              _search = v;
              _applyView();
            },
          ),
          const SizedBox(height: 8),

          // 옵션행: 섞기 / 제한 / 전체·표시개수
          Row(
            children: [
              FilterChip(
                label: Text(UiText.t('shuffle')),
                selected: _shuffle,
                onSelected: (v) {
                  setState(() => _shuffle = v);
                  _applyView();
                },
              ),
              const SizedBox(width: 8),
              _LimitPicker(
                value: _limit,
                onChanged: (v) {
                  _limit = v;
                  _applyView();
                },
              ),
              const Spacer(),
              Text(
                '${UiText.t("total")}: ${_rawItems.length} · ${UiText.t("showing")}: ${_viewItems.length}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 초성 필터(있을 때만)
          if (_initialSet.isNotEmpty) _buildInitialFilterRow(),
        ],
      ),
    );
  }

  Widget _buildInitialFilterRow() {
    final chips = <String>['ALL', ..._initialSet.toList()..sort()];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final v = chips[i];
          final selected = _initialFilter == v;
          return ChoiceChip(
            label: Text(v == 'ALL' ? UiText.t('all') : v),
            selected: selected,
            onSelected: (_) {
              setState(() => _initialFilter = v);
              _applyView();
            },
          );
        },
      ),
    );
  }

  Widget _buildList() {
    if (_viewItems.isEmpty) {
      return Center(child: Text(UiText.t('noItems')));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _viewItems.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final item = _viewItems[i];
        final text = _displayText(item);
        final glyph = _extractGlyph(item);
        final ini = _extractInitial(item);

        return ListTile(
          leading: CircleAvatar(
            radius: 14,
            child: Text('${i + 1}', style: const TextStyle(fontSize: 12)),
          ),
          title: Text(text),
          subtitle: ini == null ? null : Text('${UiText.t("initial")}: $ini'),
          trailing: glyph == null
              ? null
              : IconButton(
                  tooltip: UiText.t('practice'),
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/practice',
                      arguments: {
                        'charGlyph': glyph,
                        'allowStylePickers': true,
                        'showGuide': true,
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────
// 표시개수 픽커
// ────────────────────────────────────────────────────────────────
class _LimitPicker extends StatelessWidget {
  const _LimitPicker({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const choices = [20, 50, 100, 200, 500, 1000000];
    String label(int v) => v >= 1000000 ? '∞' : v.toString();

    return PopupMenuButton<int>(
      tooltip: UiText.t('limit'),
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final v in choices)
          PopupMenuItem<int>(
            value: v,
            child: Text('${UiText.t("limit")}: ${label(v)}'),
          ),
      ],
      child: InputChip(
        label: Text('${UiText.t("limit")} ${label(value)}'),
        avatar: const Icon(Icons.filter_alt, size: 18),
        onPressed: null,
      ),
    );
  }
}
