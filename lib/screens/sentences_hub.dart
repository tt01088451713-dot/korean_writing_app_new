// lib/screens/sentences_hub.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:korean_writing_app_new/i18n/language_state.dart';
import 'package:korean_writing_app_new/i18n/ui_texts.dart';

/// 학습자 빌드에서는 false 유지(디버그 메타 표시)
const bool kShowDebugMeta = false;

class SentencesHubPage extends StatefulWidget {
  const SentencesHubPage({super.key});

  @override
  State<SentencesHubPage> createState() => _SentencesHubPageState();
}

class _SentencesHubPageState extends State<SentencesHubPage> {
  static const _indexAsset = 'assets/data/sentence/4_sentence_index.json';

  Map<String, dynamic>? _index;
  String? _error;
  bool _loading = true;

  VoidCallback? _langListener;

  String get _lang =>
      (LanguageState.I.code.isEmpty ? 'ko' : LanguageState.I.code)
          .split('-')
          .first;

  @override
  void initState() {
    super.initState();
    _load();

    // 언어 변경 시 즉시 리빌드(제목/설명 다국어 반영)
    _langListener = () {
      if (mounted) setState(() {});
    };
    LanguageState.I.addListener(_langListener!);
  }

  @override
  void dispose() {
    if (_langListener != null) {
      LanguageState.I.removeListener(_langListener!);
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _index = null;
    });

    try {
      final raw = await rootBundle.loadString(_indexAsset);
      final j = json.decode(raw);
      if (j is! Map<String, dynamic>) {
        throw const FormatException('Index JSON must be an object.');
      }
      if (!mounted) return;
      setState(() => _index = j);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '문장 인덱스 로드 실패: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 다국어 값을 안전하게 선택(Map 또는 String 허용)
  String _pickLangAny(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    if (v is String) return v;
    if (v is Map) {
      final m = v.cast<String, dynamic>();
      final s = (m[_lang] ??
                  m['ko'] ??
                  m['en'] ??
                  (m.values.isNotEmpty ? m.values.first : ''))
              ?.toString() ??
          '';
      return s.isNotEmpty ? s : fallback;
    }
    return fallback;
  }

  /// 섹션 리스트 추출(스키마 다양성 대응: sections/sets/items/list)
  List<Map<String, dynamic>> _extractSections(Map<String, dynamic>? root) {
    if (root == null) return const [];
    for (final key in ['sections', 'sets', 'items', 'list']) {
      final v = root[key];
      if (v is List && v.isNotEmpty && v.first is Map) {
        return v.cast<Map>().map((e) => e.cast<String, dynamic>()).toList();
      }
    }
    return const [];
  }

  /// 파일 경로 보정
  /// '4_6_direction_sentences.json' -> 'assets/data/sentence/4_6_direction_sentences.json'
  String _resolveFilePath(String file) {
    if (file.isEmpty) return file;
    if (file.startsWith('assets/')) return file;
    return 'assets/data/sentence/$file';
  }

  /// 인덱스에 routing.detailRoute가 있으면 활용, 없으면 기본 상세 라우트 사용
  String get _detailRoute {
    final routing = (_index?['routing'] ?? {}) as Map?;
    final route = (routing?['detailRoute'] ?? '').toString();
    return route.isNotEmpty ? route : '/sentences/lesson';
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldTitle = _index != null
        ? _pickLangAny(_index!['title'], fallback: UiText.t('menuSentences'))
        : UiText.t('menuSentences');

    return Scaffold(
      appBar: AppBar(title: Text(scaffoldTitle)),
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
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(_error!,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      );
    }

    final desc = _pickLangAny(_index?['description']);
    final sections = _extractSections(_index);

    if (sections.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 24),
          Center(child: Text('등록된 섹션이 없습니다.')),
          SizedBox(height: 24),
        ],
      );
    }

    // 반응형 타이포그래피(가독성↑, 안정 범위 16~22pt)
    final w = MediaQuery.of(context).size.width;
    final titleFontSize = (16 * (w / 400).clamp(1.0, 1.4));
    final titleStyle = Theme.of(context)
        .textTheme
        .titleMedium
        ?.copyWith(fontSize: titleFontSize, fontWeight: FontWeight.w600);
    final descStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .78));

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: sections.length + (desc.isNotEmpty ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        // 상단 설명 카드
        if (desc.isNotEmpty && i == 0) {
          return Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(desc, style: descStyle),
            ),
          );
        }

        final idx = i - (desc.isNotEmpty ? 1 : 0);
        final s = sections[idx];

        final title = _pickLangAny(s['title'], fallback: UiText.t('open'));
        final subDesc = _pickLangAny(s['desc'] ?? s['description']);
        final id = (s['id'] ?? '').toString();

        // 하위 파일 경로 키 유연 처리(file/index/indexAsset/indexAssetPath)
        final rawPath = (s['file'] ??
                s['index'] ??
                s['indexAsset'] ??
                s['indexAssetPath'] ??
                '')
            .toString();
        final fullPath = _resolveFilePath(rawPath);

        // 디버그 메타
        final debugMeta = kShowDebugMeta
            ? 'ID: $id  ·  file: ${rawPath.split('/').last}'
            : null;

        return Card(
          clipBehavior: Clip.antiAlias,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.short_text),
            title: Text(title, style: titleStyle),
            subtitle: subDesc.isNotEmpty
                ? Text(subDesc, style: descStyle)
                : (debugMeta != null
                    ? Text(debugMeta, style: descStyle)
                    : null),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              if (fullPath.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('파일 경로가 비어 있습니다: $title')),
                );
                return;
              }
              Navigator.pushNamed(
                context,
                _detailRoute, // 기본 '/sentences/lesson'
                arguments: {
                  'file': fullPath,
                  'title': title,
                  'sectionId': id,
                },
              );
            },
          ),
        );
      },
    );
  }
}
