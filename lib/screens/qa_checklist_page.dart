import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:korean_writing_app_new/data_loader/data_loader.dart';
import 'package:korean_writing_app_new/lang_state.dart';
import 'package:korean_writing_app_new/i18n/ui_texts.dart';

/// QA 체크리스트 자산 경로
const String kQaChecklistAsset = 'assets/qa/qa_checklist.json';

/// 내부에서 항목을 고유 식별하기 위한 참조
class _QaRef {
  final int catIndex, secIndex, itemIndex;
  final String catId, secId, itemId;
  final String key; // prefs 저장 키
  _QaRef({
    required this.catIndex,
    required this.secIndex,
    required this.itemIndex,
    required this.catId,
    required this.secId,
    required this.itemId,
  }) : key = 'qa.done.$catId.$secId.$itemId';
}

class QaChecklistPage extends StatefulWidget {
  const QaChecklistPage({super.key});
  @override
  State<QaChecklistPage> createState() => _QaChecklistPageState();
}

class _QaChecklistPageState extends State<QaChecklistPage> {
  Map<String, dynamic>? _data; // 로드한 JSON
  final Map<String, bool> _done = {}; // key → 체크 여부
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final data = await loadJsonAsset(kQaChecklistAsset);
      // 최소 스키마 점검(유연 로드)
      if (data['categories'] is! List) {
        data['categories'] = <dynamic>[];
      }
      _data = data;

      // prefs에서 체크 상태 복구
      final prefs = await SharedPreferences.getInstance();
      for (final ref in _iterAllItems(data)) {
        _done[ref.key] = prefs.getBool(ref.key) ?? false;
      }
    } catch (e) {
      // 에러는 화면에 노출
      _data = {
        'title': {'ko': 'QA 체크리스트', 'en': 'QA Checklist'},
        'categories': <dynamic>[],
        '_error': e.toString(),
      };
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(String key, bool value) async {
    setState(() => _done[key] = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final ref in _iterAllItems(_data)) {
      _done[ref.key] = false;
      await prefs.remove(ref.key);
    }
    if (mounted) setState(() {});
  }

  Future<void> _markSection(int catIdx, int secIdx, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    for (final ref in _iterAllItems(_data)) {
      if (ref.catIndex == catIdx && ref.secIndex == secIdx) {
        _done[ref.key] = value;
        await prefs.setBool(ref.key, value);
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _exportResult() async {
    final now = DateTime.now().toIso8601String();
    final lang = AppLang.value;
    final export = <String, dynamic>{
      'generatedAt': now,
      'lang': lang,
      'title': pickMl(_data?['title']),
      'progress': _progressJson(),
      'checks': <dynamic>[],
    };

    for (final ref in _iterAllItems(_data)) {
      final item = _getItem(_data!, ref);
      export['checks'].add({
        'category': pickMl(_getCategory(_data!, ref)['title']),
        'section': pickMl(_getSection(_data!, ref)['title']),
        'text': pickMl(item['text']),
        'severity': item['severity'] ?? 'info',
        'done': _done[ref.key] ?? false,
        'key': ref.key,
      });
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/qa_export_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(export), encoding: const Utf8Codec());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported: ${file.path}')),
    );
  }

  Map<String, dynamic> _progressJson() {
    int total = 0, done = 0;
    for (final ref in _iterAllItems(_data)) {
      total++;
      if (_done[ref.key] == true) done++;
    }
    return {'done': done, 'total': total, 'ratio': total == 0 ? 0 : done / total};
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final title = pickMl(_data?['title']).isNotEmpty
        ? pickMl(_data?['title'])
        : 'QA Checklist';

    final prog = _progressJson();
    final ratio = (prog['ratio'] as num).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Export',
            icon: const Icon(Icons.ios_share),
            onPressed: _exportResult,
          ),
          IconButton(
            tooltip: UiText.t('reset'),
            icon: const Icon(Icons.restore),
            onPressed: _resetAll,
          ),
        ],
      ),
      body: _data == null
          ? const Center(child: Text('No data.'))
          : Column(
        children: [
          // 상단 검색 + 진행률
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: '검색(텍스트 포함)',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _query = v.trim()),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${prog['done']}/${prog['total']}'),
                    SizedBox(
                      width: 120,
                      child: LinearProgressIndicator(value: ratio.clamp(0, 1)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 본문
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              itemCount: (_data!['categories'] as List).length,
              itemBuilder: (_, catIdx) {
                final cat = (_data!['categories'] as List)[catIdx] as Map;
                final catTitle = pickMl(cat['title']);

                final sections = (cat['sections'] as List?) ?? const [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 4),
                      child: Text(
                        catTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...List.generate(sections.length, (secIdx) {
                      final sec = sections[secIdx] as Map;
                      final secTitle = pickMl(sec['title']);
                      final items = (sec['items'] as List?) ?? const [];

                      // 검색 필터에 의해 보이는 항목만 계산
                      final visibleIdx = <int>[];
                      for (var i = 0; i < items.length; i++) {
                        final it = items[i] as Map;
                        final text = pickMl(it['text']).toLowerCase();
                        if (_query.isEmpty || text.contains(_query.toLowerCase())) {
                          visibleIdx.add(i);
                        }
                      }
                      if (visibleIdx.isEmpty) return const SizedBox.shrink();

                      // 섹션 진행률
                      int sTotal = visibleIdx.length;
                      int sDone = 0;
                      for (final i in visibleIdx) {
                        final ref = _ref(cat, catIdx, sec, secIdx, items[i] as Map, i);
                        if (_done[ref.key] == true) sDone++;
                      }

                      return Card(
                        clipBehavior: Clip.hardEdge,
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                          title: Row(
                            children: [
                              Expanded(child: Text(secTitle)),
                              Text('$sDone/$sTotal',
                                  style: const TextStyle(color: Colors.black54)),
                            ],
                          ),
                          children: [
                            for (final i in visibleIdx)
                              _buildItemTile(cat, catIdx, sec, secIdx, items[i] as Map, i),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                              child: Row(
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(Icons.check_box),
                                    onPressed: () => _markSection(catIdx, secIdx, true),
                                    label: const Text('모두 체크'),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    icon: const Icon(Icons.check_box_outline_blank),
                                    onPressed: () => _markSection(catIdx, secIdx, false),
                                    label: const Text('모두 해제'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 리스트 아이템 타일
  Widget _buildItemTile(
      Map cat, int catIdx, Map sec, int secIdx, Map item, int itemIdx) {
    final ref = _ref(cat, catIdx, sec, secIdx, item, itemIdx);
    final checked = _done[ref.key] ?? false;
    final text = pickMl(item['text']);
    final sev = (item['severity'] ?? 'info') as String;

    Color? sevColor;
    IconData? sevIcon;
    switch (sev) {
      case 'error':
        sevColor = Colors.red.shade600;
        sevIcon = Icons.error_outline;
        break;
      case 'warn':
        sevColor = Colors.orange.shade700;
        sevIcon = Icons.warning_amber_outlined;
        break;
      default:
        sevColor = Colors.blueGrey;
        sevIcon = Icons.info_outline;
    }

    return CheckboxListTile(
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      value: checked,
      onChanged: (v) => _toggle(ref.key, v ?? false),
      title: Text(text),
      secondary: IconButton(
        tooltip: '자세히',
        icon: Icon(sevIcon, color: sevColor),
        onPressed: () => _showTips(item),
      ),
    );
  }

  void _showTips(Map item) {
    final tips = (item['tips'] as List?)?.map((e) => pickMl(e)).where((t) => t.isNotEmpty).toList() ?? const [];
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: tips.isEmpty
              ? const Text('추가 설명이 없습니다.')
              : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('체크 항목 참고', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...tips.map(
                    (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(t)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----- 유틸 & 파서 ----------------------------------------------------------

  /// 언어 코드 정규화
  static String _normLang(String? code) {
    if (code == null || code.isEmpty) return '';
    return code.toLowerCase();
  }

  /// 현재 언어코드에 대해 가능한 대체 키 후보 생성
  static List<String> _langCandidates(String useRaw) {
    final use = _normLang(useRaw);          // ex) "zh-cn"
    final base = use.split('-').first;      // ex) "zh"

    // 흔한 별칭들 (필요시 추가)
    final aliases = <String, String>{
      'zh-cn': 'zh',
      'zh-hans': 'zh',
      'zh-hant': 'zh-tw',
      'zh-tw': 'zh',
      'ja-jp': 'ja',
      'vi-vn': 'vi',
      'es-es': 'es',
      'fr-fr': 'fr',
      'ru-ru': 'ru',
      'mn-mn': 'mn',
    };

    final cand = <String>[
      use,                  // zh-cn
      base,                 // zh
      if (aliases[use] != null) aliases[use]!,       // zh
      if (aliases[base] != null) aliases[base]!,     // 별칭
    ];

    // 중복 제거
    final seen = <String>{};
    return [for (final c in cand) if (c.isNotEmpty && seen.add(c)) c];
  }

  /// 다국어 필드에서 현재 언어 선택 (강화 버전: 정규화/별칭/폴백)
  static String pickMl(dynamic v, {String? lang}) {
    final use = lang ?? AppLang.value; // ex) "zh-CN", "ja", "vi-VN"
    if (v == null) return '';
    if (v is String) return v;

    if (v is Map) {
      // 키를 소문자로 정규화해서 검색
      final map = <String, dynamic>{
        for (final e in v.entries) e.key.toString().toLowerCase(): e.value
      };

      // 1) 정확히 일치 / 지역코드 제거 / 별칭 순으로 탐색
      for (final key in _langCandidates(use)) {
        if (map.containsKey(key)) {
          final val = map[key];
          return val is String ? val : '$val';
        }
      }

      // 2) 일반 폴백: ko → en → 첫 값
      if (map.containsKey('ko')) return '${map['ko']}';
      if (map.containsKey('en')) return '${map['en']}';
      if (map.isNotEmpty) return '${map.values.first}';
      return '';
    }

    return '$v';
  }

  /// 맵 + 인덱스로 _QaRef 생성 (ListView에서 공통 사용)
  _QaRef _ref(Map cat, int catIdx, Map sec, int secIdx, Map item, int itemIdx) {
    final catId = (cat['id'] ?? 'cat$catIdx').toString();
    final secId = (sec['id'] ?? 'sec$secIdx').toString();
    final itemId = (item['id'] ?? 'item$itemIdx').toString();
    return _QaRef(
      catIndex: catIdx,
      secIndex: secIdx,
      itemIndex: itemIdx,
      catId: catId,
      secId: secId,
      itemId: itemId,
    );
  }

  Iterable<_QaRef> _iterAllItems(Map<String, dynamic>? data) sync* {
    if (data == null) return;
    final cats = (data['categories'] as List?) ?? const [];
    for (var ci = 0; ci < cats.length; ci++) {
      final cat = cats[ci] as Map;
      final catId = (cat['id'] ?? 'cat$ci').toString();
      final secs = (cat['sections'] as List?) ?? const [];
      for (var si = 0; si < secs.length; si++) {
        final sec = secs[si] as Map;
        final secId = (sec['id'] ?? 'sec$si').toString();
        final items = (sec['items'] as List?) ?? const [];
        for (var ii = 0; ii < items.length; ii++) {
          final item = items[ii] as Map;
          final itemId = (item['id'] ?? 'item$ii').toString();
          yield _QaRef(
            catIndex: ci,
            secIndex: si,
            itemIndex: ii,
            catId: catId,
            secId: secId,
            itemId: itemId,
          );
        }
      }
    }
  }

  Map _getCategory(Map data, _QaRef ref) =>
      (data['categories'] as List)[ref.catIndex] as Map;

  Map _getSection(Map data, _QaRef ref) =>
      ((_getCategory(data, ref)['sections']) as List)[ref.secIndex] as Map;

  Map _getItem(Map data, _QaRef ref) =>
      ((_getSection(data, ref)['items']) as List)[ref.itemIndex] as Map;
}
