// lib/screens/words_lesson_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_tts/flutter_tts.dart';

import 'package:korean_writing_app_new/i18n/language_state.dart';
import 'package:korean_writing_app_new/i18n/ui_texts.dart';

// ✅ 하단 배너 광고 공용 위젯
import 'package:korean_writing_app_new/ads/banner_ad_widget.dart';

class WordsLessonPage extends StatefulWidget {
  const WordsLessonPage({super.key});

  /// Usage:
  /// Navigator.pushNamed(context, '/words/lesson', arguments: {
  ///   'file': 'assets/data/word/3_5_market_words.json',
  ///   'title': '가게/시장 단어',
  /// });
  static Map<String, dynamic> readArgs(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    return (args is Map<String, dynamic>) ? args : const {};
  }

  @override
  State<WordsLessonPage> createState() => _WordsLessonPageState();
}

class _WordsLessonPageState extends State<WordsLessonPage> {
  final FlutterTts _tts = FlutterTts();

  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;

  bool _inited = false;
  late String _file;
  String _titleFromArgs = '';

  VoidCallback? _langListener;

  String get _langCode =>
      (LanguageState.I.code.isEmpty ? 'ko' : LanguageState.I.code)
          .split('-')
          .first;

  @override
  void initState() {
    super.initState();
    _initTTS();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;

    final args = WordsLessonPage.readArgs(context);
    _file = (args['file'] ?? '').toString();
    _titleFromArgs = (args['title'] ?? '').toString();

    // 언어 변경 시 즉시 리빌드(번역 표시 반영)
    _langListener = () {
      if (mounted) setState(() {});
    };
    LanguageState.I.addListener(_langListener!);

    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    if (_langListener != null) {
      LanguageState.I.removeListener(_langListener!);
    }
    _tts.stop();
    super.dispose();
  }

  Future<void> _initTTS() async {
    try {
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5);
      // 기본 한국어
      await _tts.setLanguage('ko-KR');
    } catch (_) {
      // 디바이스별 미지원 옵션 예외 무시(안정성)
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _data = null;
    });

    try {
      if (_file.isEmpty) throw 'lesson file path is empty';
      final raw = await rootBundle.loadString(_file);
      final jsonMap = json.decode(raw);
      if (jsonMap is! Map<String, dynamic>) {
        throw const FormatException('Lesson JSON must be an object.');
      }
      if (!mounted) return;
      setState(() => _data = jsonMap);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '단어 레슨 로드 실패: $e\n($_file)');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // 다국어 텍스트 선택(Map<{ko:,en:,...}> 지원)
  String _pickLang(Map? map, {String fallback = ''}) {
    if (map == null) return fallback;
    final m = map.cast<String, dynamic>();
    final v = (m[_langCode] ??
        m['ko'] ??
        m['en'] ??
        (m.values.isNotEmpty ? m.values.first : ''));
    final s = (v ?? '').toString();
    return s.isNotEmpty ? s : fallback;
  }

  Future<void> _speak(Map item) async {
    try {
      final tts = (item['tts'] ?? {}) as Map;
      final text =
      (tts['text'] ?? item['text'] ?? item['word'] ?? '').toString().trim();
      if (text.isEmpty) return;

      final lang = (tts['lang'] ?? 'ko-KR').toString();
      final rate = ((tts['rate'] ?? 0.5) as num).toDouble().clamp(0.1, 1.0);
      final pitch = ((tts['pitch'] ?? 1.0) as num).toDouble().clamp(0.5, 2.0);
      final volume =
      ((tts['volume'] ?? 1.0) as num).toDouble().clamp(0.0, 1.0);

      await _tts.stop();
      await _tts.setLanguage(lang);
      await _tts.setSpeechRate(rate);
      await _tts.setPitch(pitch);
      await _tts.setVolume(volume);
      await _tts.speak(text);
    } catch (_) {
      // TTS 미지원/권한 문제 등은 조용히 무시
    }
  }

  @override
  Widget build(BuildContext context) {
    final derivedTitle = _pickLang(_data?['title']);
    final appBarTitle = _titleFromArgs.isNotEmpty
        ? _titleFromArgs
        : (derivedTitle.isEmpty ? UiText.t('menuWords') : derivedTitle);

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(context),
      ),
      // ─────────────────────────────
      // 하단 배너 광고 – 공용 BannerAdArea 사용
      // (광고 제거를 구매하면 BannerAdArea 내부에서 자동으로 숨김)
      // ─────────────────────────────
      bottomNavigationBar: const SafeArea(
        top: false,
        child: BannerAdArea(),
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
            child: SelectableText(
              _error!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      );
    }
    return _buildContent(context);
  }

  // 스키마 A: { "lessons":[ {title, items:[...]}, ... ] }
  // 스키마 B: { "items":[ ... ] }
  Widget _buildContent(BuildContext context) {
    // 반응형 폰트(16~22pt) – 가독성/선명도 향상
    final w = MediaQuery.of(context).size.width;
    final titleFontSize = (16 * (w / 400).clamp(1.0, 1.4));
    final titleStyle = Theme.of(context)
        .textTheme
        .titleMedium
        ?.copyWith(fontSize: titleFontSize, fontWeight: FontWeight.w600);
    final subStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .78));

    final intro = _pickLang(_data?['intro'] ?? _data?['description']);
    final lessons = (_data?['lessons'] as List?)?.cast<Map>();

    if (lessons != null && lessons.isNotEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        itemCount: lessons.length + (intro.isNotEmpty ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          if (intro.isNotEmpty && i == 0) {
            return Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(intro, style: subStyle),
              ),
            );
          }
          final idx = i - (intro.isNotEmpty ? 1 : 0);
          final m = lessons[idx];
          final t = _pickLang(m['title'], fallback: UiText.t('open'));
          final items = (m['items'] as List?)?.cast<Map>() ?? const [];

          return Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              initiallyExpanded: false,
              title: Text(t, style: titleStyle),
              subtitle: Text(
                '${items.length} ${UiText.t('items')}',
                style: subStyle,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              children: [
                for (final it in items) _wordTile(context, it),
              ],
            ),
          );
        },
      );
    }

    // 스키마 B
    final items = (_data?['items'] as List? ?? []).cast<Map>();
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 24),
          Center(child: Text('표시할 단어가 없습니다.')),
          SizedBox(height: 24),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: items.length + (intro.isNotEmpty ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        if (intro.isNotEmpty && i == 0) {
          return Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(intro, style: subStyle),
            ),
          );
        }
        final idx = i - (intro.isNotEmpty ? 1 : 0);
        return _wordTile(context, items[idx]);
      },
    );
  }

  Widget _wordTile(BuildContext context, Map it) {
    // 단어/표제어
    final word = (it['text'] ?? it['word'] ?? '').toString();

    // 뜻(다국어 map 또는 단일 문자열 지원)
    String glossStr = '';
    final meanings = it['meanings'] ?? it['translations'] ?? it['gloss'];
    if (meanings is Map) {
      glossStr = _pickLang(meanings);
    } else if (meanings is String) {
      glossStr = meanings;
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.text_fields),
        title: Text(
          word,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        subtitle: glossStr.isNotEmpty ? Text(glossStr) : null,
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
                if (word.trim().isEmpty) return;
                // 쓰기 연습 화면으로 이동
                Navigator.pushNamed(
                  context,
                  '/practice',
                  arguments: {'charGlyph': word},
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
