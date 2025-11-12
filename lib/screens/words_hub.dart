// lib/screens/words_hub.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:korean_writing_app_new/i18n/language_state.dart';
import 'package:korean_writing_app_new/i18n/ui_texts.dart';

/// 디버그용 상단 메타 표시(필요 시 true)
const bool kShowDebugMeta = false;

class WordsHubPage extends StatefulWidget {
  const WordsHubPage({super.key});

  static Map<String, dynamic> readArgs(BuildContext context) {
    final a = ModalRoute.of(context)?.settings.arguments;
    return (a is Map<String, dynamic>) ? a : const {};
  }

  @override
  State<WordsHubPage> createState() => _WordsHubPageState();
}

class _WordsHubPageState extends State<WordsHubPage> {
  Map<String, dynamic>? _index;
  String? _error;
  bool _loading = true;

  bool _inited = false;
  late String _indexPath; // e.g., assets/data/word/3_word_index.json
  late String _appBarTitle; // 상단 제목

  VoidCallback? _langListener;

  String get _lang =>
      (LanguageState.I.code.isEmpty ? 'ko' : LanguageState.I.code)
          .split('-')
          .first;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;

    final args = WordsHubPage.readArgs(context);
    _indexPath =
        (args['index'] ?? 'assets/data/word/3_word_index.json').toString();
    _appBarTitle = (args['title'] ?? UiText.t('menuWords')).toString();

    // 언어 변경 시 즉시 리빌드
    _langListener = () => mounted ? setState(() {}) : null;
    LanguageState.I.addListener(_langListener!);

    _load();
  }

  @override
  void dispose() {
    if (_langListener != null) LanguageState.I.removeListener(_langListener!);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _index = null;
    });

    try {
      final raw = await rootBundle.loadString(_indexPath);
      final m = json.decode(raw);
      if (m is! Map<String, dynamic>) {
        throw const FormatException('Index JSON must be an object.');
      }
      if (!mounted) return;
      setState(() => _index = m);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '단어 인덱스 로드 실패:\n$e\n($_indexPath)');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // 다국어 선택(문자열/맵 모두 지원)
  String _pickLang(dynamic mapOrStr, {String fallback = ''}) {
    if (mapOrStr == null) return fallback;
    if (mapOrStr is String) return mapOrStr;
    if (mapOrStr is Map) {
      final m = mapOrStr.cast<String, dynamic>();
      final s = (m[_lang] ??
              m['ko'] ??
              m['en'] ??
              (m.values.isNotEmpty ? m.values.first : ''))
          .toString();
      return s.isNotEmpty ? s : fallback;
    }
    return fallback;
  }

  // 상대 경로 보정
  String _resolveFilePath(String file) {
    if (file.isEmpty) return file;
    if (file.startsWith('assets/')) return file;
    return 'assets/data/word/$file';
  }

  @override
  Widget build(BuildContext context) {
    final title =
        _appBarTitle.isNotEmpty ? _appBarTitle : UiText.t('menuWords');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 180),
          Center(child: CircularProgressIndicator()),
          SizedBox(height: 180),
        ],
      );
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              _error!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      );
    }
    return _buildList(context);
  }

  Widget _buildList(BuildContext context) {
    final intro = _pickLang(_index?['intro'] ?? _index?['description']);

    // 상단 메타 디버그
    final topKeys = (_index != null)
        ? _index!.keys.map((e) => e.toString()).toList()
        : const <String>[];

    // 화면 너비 기반 반응형 타이틀 폰트 (16–22pt)
    final w = MediaQuery.of(context).size.width;
    final labelFontSize = (16 * (w / 400).clamp(1.0, 1.4));
    final titleStyle = Theme.of(context)
        .textTheme
        .titleMedium
        ?.copyWith(fontSize: labelFontSize, fontWeight: FontWeight.w600);
    final subtitleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .78));

    // ---- 1) sections / sets / groups / categories / topics / list/items 중 첫 컬렉션 선택
    List<Map>? extractAnySets(Map<String, dynamic>? root) {
      if (root == null) return null;
      const candidates = [
        'sections', // 우선
        'sets',
        'groups',
        'categories',
        'topics',
        'list',
        'items',
      ];
      for (final k in candidates) {
        final v = root[k];
        if (v is List && v.isNotEmpty && v.first is Map) {
          return v.cast<Map>();
        }
      }
      return null;
    }

    final sets = extractAnySets(_index);

    if (sets != null && sets.isNotEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        itemCount:
            sets.length + (intro.isNotEmpty ? 1 : 0) + (kShowDebugMeta ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          // 소개 카드
          if (intro.isNotEmpty && i == 0) {
            return Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(right: 10, top: 2),
                      child: Icon(Icons.info_outline),
                    ),
                    Expanded(child: Text(intro, style: subtitleStyle)),
                  ],
                ),
              ),
            );
          }

          // 디버그 메타
          if (kShowDebugMeta && i == (intro.isNotEmpty ? 1 : 0)) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text('Top-level keys: ${topKeys.join(', ')}'),
              ),
            );
          }

          final idx = i - (intro.isNotEmpty ? 1 : 0) - (kShowDebugMeta ? 1 : 0);
          final it = sets[idx];

          String titleOf(Map m) => _pickLang(m['title'], fallback: '')
              .ifEmpty(() => _pickLang(m['name'], fallback: ''))
              .ifEmpty(() => UiText.t('open'));

          // 하위 인덱스 파일 키 통합(file / indexAsset / index / indexAssetPath)
          String pickIndexFile(Map m) {
            final raw = (m['file'] ??
                    m['indexAsset'] ??
                    m['index'] ??
                    m['indexAssetPath'] ??
                    '')
                .toString();
            return _resolveFilePath(raw);
          }

          final t = titleOf(it);
          final d = _pickLang(it['desc'] ?? it['description']);
          final fullPath = pickIndexFile(it);

          return Card(
            clipBehavior: Clip.antiAlias,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.grid_view),
              title: Text(t, style: titleStyle),
              subtitle: d.isNotEmpty
                  ? Text(d, style: subtitleStyle)
                  : (kShowDebugMeta && fullPath.isNotEmpty
                      ? Text('file: ${fullPath.split('/').last}')
                      : null),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                if (fullPath.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('파일 경로가 비어 있습니다: $t')),
                  );
                  return;
                }
                Navigator.pushNamed(
                  context,
                  '/words/lesson',
                  arguments: {'file': fullPath, 'title': t},
                );
              },
            ),
          );
        },
      );
    }

    // ---- 2) lessons/items 직접 나열(레거시 호환)
    final lessonsRaw =
        _index?['lessons'] ?? _index?['items'] ?? _index?['list'];
    if (lessonsRaw is List && lessonsRaw.isNotEmpty) {
      final lessons = lessonsRaw.cast<Map>();
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        itemCount: lessons.length +
            (intro.isNotEmpty ? 1 : 0) +
            (kShowDebugMeta ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          if (intro.isNotEmpty && i == 0) {
            return Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(intro, style: subtitleStyle),
              ),
            );
          }
          if (kShowDebugMeta && i == (intro.isNotEmpty ? 1 : 0)) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text('Top-level keys: ${topKeys.join(', ')}'),
              ),
            );
          }

          final idx = i - (intro.isNotEmpty ? 1 : 0) - (kShowDebugMeta ? 1 : 0);
          final it = lessons[idx];

          final t = _pickLang(it['title'])
              .ifEmpty(() => _pickLang(it['name']))
              .ifEmpty(() => UiText.t('open'));
          final d = _pickLang(it['desc'] ?? it['description']);
          final file = (it['file'] ?? '').toString();
          final fullPath = file.isEmpty ? _indexPath : _resolveFilePath(file);

          return Card(
            clipBehavior: Clip.antiAlias,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.text_snippet_outlined),
              title: Text(t, style: titleStyle),
              subtitle: d.isNotEmpty ? Text(d, style: subtitleStyle) : null,
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/words/lesson',
                  arguments: {'file': fullPath, 'title': t},
                );
              },
            ),
          );
        },
      );
    }

    // ---- 3) 아무 것도 못 찾은 경우
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        if (kShowDebugMeta)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Top-level keys: ${topKeys.join(', ')}'),
          ),
        const SizedBox(height: 24),
        const Center(
          child:
              Text('표시할 항목이 없습니다. 인덱스 스키마(sets/sections/lessons/items) 확인 필요.'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// 작은 헬퍼
extension _StringEmpty on String {
  String ifEmpty(String Function() orElse) => isEmpty ? orElse() : this;
}
