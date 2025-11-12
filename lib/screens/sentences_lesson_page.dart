// lib/screens/sentences_lesson_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_tts/flutter_tts.dart';

import 'package:korean_writing_app_new/i18n/language_state.dart';
import 'package:korean_writing_app_new/i18n/ui_texts.dart';

class SentencesLessonPage extends StatefulWidget {
  const SentencesLessonPage({super.key});

  /// 예시:
  /// Navigator.pushNamed(context, '/sentences/lesson', arguments: {
  ///   "file": "assets/data/sentence/4_7_time_sentences.json",
  ///   "title": "시간/약속"
  /// });
  static Map<String, dynamic> readArgs(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    return (args is Map<String, dynamic>) ? args : const {};
  }

  @override
  State<SentencesLessonPage> createState() => _SentencesLessonPageState();
}

class _SentencesLessonPageState extends State<SentencesLessonPage> {
  final _tts = FlutterTts();

  Map<String, dynamic>? _lesson;
  String? _error;
  bool _loading = true;

  // arguments
  bool _inited = false;
  late Map<String, dynamic> _args;
  String _file = '';
  String _titleFromArgs = '';

  VoidCallback? _langListener;

  String get _lang =>
      (LanguageState.I.code.isEmpty ? 'ko' : LanguageState.I.code)
          .split('-')
          .first;

  @override
  void initState() {
    super.initState();
    _initTTS();

    // 언어 변경 시 즉시 리렌더
    _langListener = () {
      if (mounted) setState(() {});
    };
    LanguageState.I.addListener(_langListener!);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;

    _args = SentencesLessonPage.readArgs(context);
    _file = (_args['file'] ?? '').toString();
    _titleFromArgs = (_args['title'] ?? '').toString();

    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _initTTS() async {
    try {
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5);
    } catch (_) {
      // 일부 플랫폼 미지원 시 무시
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _lesson = null;
    });

    try {
      if (_file.isEmpty) throw 'lesson file path is empty';
      final raw = await rootBundle.loadString(_file);
      final j = json.decode(raw);
      if (j is! Map<String, dynamic>) {
        throw const FormatException('Lesson JSON must be an object.');
      }
      if (!mounted) return;
      setState(() => _lesson = j);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '문장 레슨 로드 실패: $e\n($_file)');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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

  Future<void> _speak(Map item) async {
    try {
      final tts = (item['tts'] ?? const {}) as Map;
      final text = (tts['text'] ?? item['text'] ?? '').toString();
      if (text.trim().isEmpty) return;

      final lang = (tts['lang'] ?? 'ko-KR').toString();
      final rate = ((tts['rate'] ?? 0.5) as num).toDouble().clamp(0.1, 1.0);
      final pitch = ((tts['pitch'] ?? 1.0) as num).toDouble().clamp(0.5, 2.0);
      final volume = ((tts['volume'] ?? 1.0) as num).toDouble().clamp(0.0, 1.0);

      await _tts.stop();
      await _tts.setLanguage(lang);
      await _tts.setSpeechRate(rate);
      await _tts.setPitch(pitch);
      await _tts.setVolume(volume);
      await _tts.speak(text);
    } catch (_) {}
  }

  @override
  void dispose() {
    try {
      _tts.stop();
    } catch (_) {}
    if (_langListener != null) {
      LanguageState.I.removeListener(_langListener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final titleFs = (18 * (w / 400).clamp(1.0, 1.35));
    final sentenceFs = (17 * (w / 400).clamp(1.0, 1.35));
    final descStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .78));

    final derivedTitle = _pickLangAny(_lesson?['title']);
    final appBarTitle = _titleFromArgs.isNotEmpty
        ? _titleFromArgs
        : (derivedTitle.isEmpty ? UiText.t('sentences') : derivedTitle);

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(
            titleFs: titleFs, sentenceFs: sentenceFs, descStyle: descStyle),
      ),
    );
  }

  Widget _buildBody({
    required double titleFs,
    required double sentenceFs,
    required TextStyle? descStyle,
  }) {
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

    final intro = _pickLangAny(_lesson?['overview'])
        .ifEmpty(() => _pickLangAny(_lesson?['description']))
        .ifEmpty(() => _pickLangAny(_lesson?['introduction']));

    final hasIntro = intro.trim().isNotEmpty;

    final lessons = (_lesson?['lessons'] as List?)?.whereType<Map>().toList();
    final items = (_lesson?['items'] as List?)?.whereType<Map>().toList();

    if ((lessons == null || lessons.isEmpty) &&
        (items == null || items.isEmpty)) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 24),
          Center(child: Text('표시할 문장이 없습니다.')),
          SizedBox(height: 24),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: (lessons != null && lessons.isNotEmpty)
          ? lessons.length + (hasIntro ? 1 : 0)
          : (items?.length ?? 0) + (hasIntro ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        if (hasIntro && i == 0) {
          return Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(intro, style: descStyle),
            ),
          );
        }

        // lessons 구조
        if (lessons != null && lessons.isNotEmpty) {
          final idx = i - (hasIntro ? 1 : 0);
          final m = lessons[idx].cast<String, dynamic>();
          final t = _pickLangAny(m['title'], fallback: UiText.t('open'));
          final sub = _pickLangAny(m['desc'] ?? m['description']);
          final its =
              (m['items'] as List?)?.whereType<Map>().toList() ?? const [];

          return Card(
            clipBehavior: Clip.antiAlias,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              leading: const Icon(Icons.folder_open),
              title: Text(t,
                  style: TextStyle(
                      fontSize: titleFs, fontWeight: FontWeight.w600)),
              subtitle: sub.isNotEmpty
                  ? Text(sub, style: descStyle)
                  : Text('${its.length} items', style: descStyle),
              children: [
                const SizedBox(height: 4),
                for (final it in its) _sentenceTile(it, sentenceFs),
                const SizedBox(height: 8),
              ],
            ),
          );
        }

        // 단일 items 구조
        final idx = i - (hasIntro ? 1 : 0);
        return _sentenceTile(items![idx], sentenceFs);
      },
    );
  }

  Widget _sentenceTile(Map raw, double sentenceFs) {
    final it = raw.cast<String, dynamic>();
    final sentence = (it['text'] ?? '').toString();
    final gloss = _pickLangAny(it['translations'] ?? it['meanings']);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.short_text),
        title: Text(
          sentence,
          style: TextStyle(fontSize: sentenceFs, fontWeight: FontWeight.w600),
        ),
        subtitle: gloss.isNotEmpty ? Text(gloss) : null,
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: UiText.t('listen'),
              icon: const Icon(Icons.volume_up),
              onPressed: () => _speak(it),
            ),
            IconButton(
              tooltip: UiText.t('writingPractice'),
              icon: const Icon(Icons.edit),
              onPressed: () {
                if (sentence.trim().isEmpty) return;
                Navigator.pushNamed(
                  context,
                  '/practice',
                  arguments: {'charGlyph': sentence},
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 안전한 ifEmpty 헬퍼
extension _SafeEmpty on String {
  String ifEmpty(String Function() orElse) => trim().isEmpty ? orElse() : this;
}
