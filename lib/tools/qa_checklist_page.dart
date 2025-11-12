import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

const _kChecklistAsset = 'assets/tools/qa_checklist.json';
const _kProgressKey = 'qa.checklist.progress.v1'; // 버전 바꿀 때 키만 올려주세요.

class QaChecklistPage extends StatefulWidget {
  const QaChecklistPage({super.key});
  @override
  State<QaChecklistPage> createState() => _QaChecklistPageState();
}

class _QaChecklistPageState extends State<QaChecklistPage> {
  Map<String, dynamic>? _data;
  Set<String> _done = {};
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    // 1) 자산 JSON은 읽기 전용
    final raw = await rootBundle.loadString(_kChecklistAsset);
    final map = jsonDecode(raw) as Map<String, dynamic>;
    // 2) 진행상태는 로컬에만 저장
    final prefs = await SharedPreferences.getInstance();
    _done = (prefs.getStringList(_kProgressKey) ?? const <String>[]).toSet();
    setState(() {
      _data = map;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kProgressKey, _done.toList());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('진행상태가 저장되었습니다.')),
    );
  }

  Future<void> _resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kProgressKey);
    setState(() => _done.clear());
  }

  void _toggle(String id, bool v) {
    setState(() {
      if (v) {
        _done.add(id);
      } else {
        _done.remove(id);
      }
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('검증·수정·재빌드 체크리스트'),
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: '진행 초기화',
            onPressed: _resetProgress,
            icon: const Icon(Icons.restore),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '항목 검색…',
                filled: true,
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (s) => setState(() => _query = s.trim()),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final sections = (_data?['sections'] as List?) ?? const [];
    final total =
        sections.expand((s) => (s['items'] as List? ?? const [])).length;
    final done = _done.length.clamp(0, total);
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        Text('진행률: $done / $total',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...sections.map((s) => _Section(
              title: '${s['title'] ?? ''}',
              items: (s['items'] as List? ?? const [])
                  .map((e) => _Item.fromJson(e))
                  .where((it) =>
                      _query.isEmpty ||
                      it.label.contains(_query) ||
                      it.note.contains(_query))
                  .toList(),
              done: _done,
              onToggle: _toggle,
            )),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.items,
    required this.done,
    required this.onToggle,
  });

  final String title;
  final List<_Item> items;
  final Set<String> done;
  final void Function(String id, bool value) onToggle;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final sectionDone = items.where((e) => done.contains(e.id)).length;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(title),
        subtitle: Text('$sectionDone / ${items.length}'),
        children: [
          for (final it in items)
            CheckboxListTile(
              value: done.contains(it.id),
              onChanged: (v) => onToggle(it.id, v ?? false),
              title: Text(it.label),
              subtitle: it.note.isEmpty ? null : Text(it.note),
            )
        ],
      ),
    );
  }
}

class _Item {
  final String id;
  final String label;
  final String note;
  const _Item({required this.id, required this.label, required this.note});
  factory _Item.fromJson(Map j) => _Item(
        id: '${j['id']}',
        label: '${j['label'] ?? ''}',
        note: '${j['note'] ?? ''}',
      );
}
