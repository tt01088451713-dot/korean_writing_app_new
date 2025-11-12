// lib/tts_helpers.dart
import 'dart:collection';
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 큐가 가득 찼을 때 동작 정책
enum QueueOverflowPolicy { rejectNew, dropOldest }

class AppTts {
  AppTts._();

  // ── Core ────────────────────────────────────────────────────────────────────
  static final FlutterTts _tts = FlutterTts();
  static bool _inited = false;
  static bool _prefsLoaded = false;

  // 현재 설정 (동적 변경 가능)
  static double _rate = 0.5; // 0.0 ~ 1.0
  static double _pitch = 1.0; // 0.5 ~ 2.0
  static double _volume = 1.0; // 0.0 ~ 1.0

  // 기억해두는 음성/로케일
  static Map<String, String>? _koVoice;
  static Map<String, String>? _jaVoice;
  static String _koLocale = 'ko-KR';
  static String _jaLocale = 'ja-JP';

  // ── 라벨(표시명) → 발음 예외 ─────────────────────────────────────────────────
  static const Map<String, String> _labelOverrides = {
    'arae-a': '아래아',
  };

  // 자음자 이름 매핑
  static const Map<String, String> _name = {
    'ㄱ': '기역',
    'ㄲ': '쌍기역',
    'ㄴ': '니은',
    'ㄷ': '디귿',
    'ㄸ': '쌍디귿',
    'ㄹ': '리을',
    'ㅁ': '미음',
    'ㅂ': '비읍',
    'ㅃ': '쌍비읍',
    'ㅅ': '시옷',
    'ㅆ': '쌍시옷',
    'ㅇ': '이응',
    'ㅈ': '지읒',
    'ㅉ': '쌍지읒',
    'ㅊ': '치읓',
    'ㅋ': '키읔',
    'ㅌ': '티읕',
    'ㅍ': '피읖',
    'ㅎ': '히읗',
    'ㄳ': '기역시옷',
    'ㄵ': '니은지읒',
    'ㄶ': '니은히읗',
    'ㄺ': '리을기역',
    'ㄻ': '리을미음',
    'ㄼ': '리을비읍',
    'ㄽ': '리을시옷',
    'ㄾ': '리을티읕',
    'ㄿ': '리을피읖',
    'ㅀ': '리을히읗',
    'ㅄ': '비읍시옷',
  };

  // 모음자: 글리프 → 한국어 발음
  static const Map<String, String> _vowelPronByGlyph = {
    'ㅏ': '아',
    'ㅑ': '야',
    'ㅓ': '어',
    'ㅕ': '여',
    'ㅗ': '오',
    'ㅛ': '요',
    'ㅜ': '우',
    'ㅠ': '유',
    'ㅡ': '으',
    'ㅣ': '이',
    'ㅐ': '애',
    'ㅒ': '얘',
    'ㅔ': '에',
    'ㅖ': '예',
    'ㅘ': '와',
    'ㅙ': '왜',
    'ㅚ': '외',
    'ㅝ': '워',
    'ㅞ': '웨',
    'ㅟ': '위',
    'ㅢ': '의',
  };

  // 라틴 라벨 → 한국어 발음
  static const Map<String, String> _latinToKoVowel = {
    'a': '아',
    'ya': '야',
    'eo': '어',
    'yeo': '여',
    'o': '오',
    'yo': '요',
    'u': '우',
    'yu': '유',
    'eu': '으',
    'i': '이',
    'ae': '애',
    'yae': '얘',
    'e': '에',
    'ye': '예',
    'wa': '와',
    'wae': '왜',
    'oe': '외',
    'wo': '워',
    'we': '웨',
    'wi': '위',
    'ui': '의',
  };

  // ── Queue(말하기 큐) ────────────────────────────────────────────────────────
  static final Queue<_TtsJob> _queue = Queue<_TtsJob>();
  static bool _processingQueue = false;

  static int _queueMax = 32;
  static QueueOverflowPolicy _overflowPolicy = QueueOverflowPolicy.rejectNew;

  // ── Prefs Keys ──────────────────────────────────────────────────────────────
  static const _kRate = 'tts_rate';
  static const _kPitch = 'tts_pitch';
  static const _kVolume = 'tts_volume';
  static const _kKoLocale = 'tts_ko_locale';
  static const _kJaLocale = 'tts_ja_locale';
  static const _kKoVoice = 'tts_ko_voice_json';
  static const _kJaVoice = 'tts_ja_voice_json';
  static const _kQueueMax = 'tts_queue_max';
  static const _kQueuePolicy = 'tts_queue_policy'; // 'reject' | 'drop'

  // ── Init ────────────────────────────────────────────────────────────────────
  static Future<void> _ensureInit() async {
    if (!_prefsLoaded) {
      await _loadPrefs();
      _prefsLoaded = true;
    }
    if (_inited) return;

    await _tts.awaitSpeakCompletion(true);
    await _tts.setSpeechRate(_rate);
    await _tts.setVolume(_volume);
    try {
      await _tts.setPitch(_pitch);
    } catch (_) {}

    try {
      _tts.setStartHandler(() => print('[TTS] start'));
      _tts.setCompletionHandler(() => print('[TTS] complete'));
      _tts.setErrorHandler((msg) => print('[TTS] error: $msg'));
    } catch (_) {}

    // 기기 보이스 목록을 확인하고, 저장된 보이스가 통하지 않으면 자동 탐색
    final List<dynamic>? rawVoices = await _tts.getVoices;
    final hasKo = await _tryAdoptVoice(_koVoice,
        fallbackLang: 'ko', rawVoices: rawVoices, setKo: true);
    final hasJa = await _tryAdoptVoice(_jaVoice,
        fallbackLang: 'ja', rawVoices: rawVoices, setKo: false);

    // 한국어 기본 설정
    await _tts.setLanguage(_koLocale);
    if (!hasKo && rawVoices != null) {
      // ko 보이스 자동 탐색
      for (final v in rawVoices) {
        final m = Map<String, String>.from(v as Map);
        final locale = (m['locale'] ?? '').toLowerCase();
        final name = (m['name'] ?? '').toLowerCase();
        if (locale.startsWith('ko') || name.contains('korean')) {
          _koVoice = m;
          if (m['locale'] != null) _koLocale = m['locale']!;
          try {
            await _tts.setVoice(m);
          } catch (_) {}
          break;
        }
      }
    }

    _inited = true;
  }

  static Future<bool> _tryAdoptVoice(Map<String, String>? saved,
      {required String fallbackLang,
      required List<dynamic>? rawVoices,
      required bool setKo}) async {
    if (rawVoices == null) return false;
    if (saved != null) {
      // 저장된 보이스가 현재 기기에도 존재하는지 확인
      final targetName = (saved['name'] ?? '').toLowerCase();
      final targetLocale = (saved['locale'] ?? '').toLowerCase();
      for (final v in rawVoices) {
        final m = Map<String, String>.from(v as Map);
        final name = (m['name'] ?? '').toLowerCase();
        final locale = (m['locale'] ?? '').toLowerCase();
        if (name == targetName && locale == targetLocale) {
          if (setKo) {
            _koVoice = m;
            if (m['locale'] != null) _koLocale = m['locale']!;
          } else {
            _jaVoice = m;
            if (m['locale'] != null) _jaLocale = m['locale']!;
          }
          try {
            await _tts.setVoice(m);
          } catch (_) {}
          return true;
        }
      }
    }
    // 저장된 보이스가 현재 기기에 없으면 false
    return false;
  }

  // ── Prefs Save/Load ────────────────────────────────────────────────────────
  static Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    _rate = p.getDouble(_kRate) ?? _rate;
    _pitch = p.getDouble(_kPitch) ?? _pitch;
    _volume = p.getDouble(_kVolume) ?? _volume;

    _koLocale = p.getString(_kKoLocale) ?? _koLocale;
    _jaLocale = p.getString(_kJaLocale) ?? _jaLocale;

    _queueMax = p.getInt(_kQueueMax) ?? _queueMax;
    _overflowPolicy = (p.getString(_kQueuePolicy) ?? 'reject') == 'drop'
        ? QueueOverflowPolicy.dropOldest
        : QueueOverflowPolicy.rejectNew;

    final koJson = p.getString(_kKoVoice);
    final jaJson = p.getString(_kJaVoice);
    if (koJson != null && koJson.isNotEmpty) {
      try {
        _koVoice = Map<String, String>.from(jsonDecode(koJson));
      } catch (_) {}
    }
    if (jaJson != null && jaJson.isNotEmpty) {
      try {
        _jaVoice = Map<String, String>.from(jsonDecode(jaJson));
      } catch (_) {}
    }
  }

  static Future<void> _save<T>(String key, T value) async {
    final p = await SharedPreferences.getInstance();
    if (value is double) {
      await p.setDouble(key, value);
      return;
    }
    if (value is int) {
      await p.setInt(key, value);
      return;
    }
    if (value is String) {
      await p.setString(key, value);
      return;
    }
  }

  // ── Public: 즉시 발화(덮어쓰기) ─────────────────────────────────────────────
  static Future<void> speak(String text) async {
    await _ensureInit();
    await _speakKo(text, interrupt: true);
  }

  static Future<void> speakGlyphOrText(String glyph, {String? label}) async {
    await _ensureInit();
    final plan = _planPronunciation(glyph: glyph, label: label);
    await _executePlan(plan, interrupt: true);
  }

  // ── Public: 큐 발화(순차) ───────────────────────────────────────────────────
  static Future<void> enqueue(String text) async {
    await tryEnqueue(text);
  }

  static Future<void> enqueueGlyphOrText(String glyph, {String? label}) async {
    await tryEnqueueGlyphOrText(glyph, label: label);
  }

  static Future<bool> tryEnqueue(String text) async {
    if (text.trim().isEmpty) return false;
    if (!_pushJob(_TtsJob.text(text))) return false;
    _kickQueue();
    return true;
  }

  static Future<bool> tryEnqueueGlyphOrText(String glyph,
      {String? label}) async {
    if (glyph.trim().isEmpty && (label?.trim().isEmpty ?? true)) return false;
    if (!_pushJob(_TtsJob.glyph(glyph, label: label))) return false;
    _kickQueue();
    return true;
  }

  static void clearQueue() => _queue.clear();

  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  static Future<void> cancelAll() async {
    _queue.clear();
    try {
      await _tts.stop();
    } catch (_) {}
  }

  // ── Public: 동적 설정 API (+ 즉시 저장) ─────────────────────────────────────
  static Future<void> setSpeechRate(double rate) async {
    _rate = rate;
    await _save(_kRate, _rate);
    await _ensureInit();
    try {
      await _tts.setSpeechRate(_rate);
    } catch (_) {}
  }

  static Future<void> setPitch(double pitch) async {
    _pitch = pitch;
    await _save(_kPitch, _pitch);
    await _ensureInit();
    try {
      await _tts.setPitch(_pitch);
    } catch (_) {}
  }

  static Future<void> setVolume(double volume) async {
    _volume = volume;
    await _save(_kVolume, _volume);
    await _ensureInit();
    try {
      await _tts.setVolume(_volume);
    } catch (_) {}
  }

  static Future<void> setKoLocale(String locale) async {
    _koLocale = locale;
    await _save(_kKoLocale, _koLocale);
  }

  static Future<void> setJaLocale(String locale) async {
    _jaLocale = locale;
    await _save(_kJaLocale, _jaLocale);
  }

  static Future<void> setKoVoiceMap(Map<String, String> voice) async {
    await _ensureInit();
    _koVoice = Map<String, String>.from(voice);
    await _save(_kKoVoice, jsonEncode(_koVoice));
  }

  static Future<void> setJaVoiceMap(Map<String, String> voice) async {
    await _ensureInit();
    _jaVoice = Map<String, String>.from(voice);
    await _save(_kJaVoice, jsonEncode(_jaVoice));
  }

  static void setQueueMax(int n) {
    _queueMax = n.clamp(1, 9999);
    _shrinkQueueIfNeeded();
    _save(_kQueueMax, _queueMax);
  }

  static void setQueueOverflowPolicy(QueueOverflowPolicy policy) {
    _overflowPolicy = policy;
    _shrinkQueueIfNeeded();
    _save(_kQueuePolicy,
        policy == QueueOverflowPolicy.dropOldest ? 'drop' : 'reject');
  }

  static Future<void> forceLanguageKo(String text,
      {bool interrupt = true}) async {
    await _ensureInit();
    await _speakKo(text, interrupt: interrupt);
  }

  static Future<void> forceLanguageJa(String text,
      {bool interrupt = true}) async {
    await _ensureInit();
    await _speakJa(text, interrupt: interrupt);
  }

  // 현재 설정 조회
  static double get rate => _rate;
  static double get pitch => _pitch;
  static double get volume => _volume;
  static String get koLocale => _koLocale;
  static String get jaLocale => _jaLocale;
  static int get queueMax => _queueMax;
  static QueueOverflowPolicy get overflowPolicy => _overflowPolicy;
  static int get queueLength => _queue.length;

  // ── Internal: Queue helpers ────────────────────────────────────────────────
  static bool _pushJob(_TtsJob job) {
    if (_queue.length < _queueMax) {
      _queue.add(job);
      return true;
    }
    switch (_overflowPolicy) {
      case QueueOverflowPolicy.rejectNew:
        return false;
      case QueueOverflowPolicy.dropOldest:
        while (_queue.length >= _queueMax && _queue.isNotEmpty) {
          _queue.removeFirst();
        }
        _queue.add(job);
        return true;
    }
  }

  static void _shrinkQueueIfNeeded() {
    if (_queue.length <= _queueMax) return;
    if (_overflowPolicy == QueueOverflowPolicy.rejectNew) return;
    while (_queue.length > _queueMax && _queue.isNotEmpty) {
      _queue.removeFirst();
    }
  }

  static void _kickQueue() {
    if (_processingQueue) return;
    _processingQueue = true;
    _processQueue();
  }

  static Future<void> _processQueue() async {
    await _ensureInit();
    while (_queue.isNotEmpty) {
      final job = _queue.removeFirst();
      final plan = job.kind == _JobKind.text
          ? _Plan.toKo(job.text!)
          : _planPronunciation(glyph: job.glyph!, label: job.label);

      await _executePlan(plan, interrupt: false);
      await Future.delayed(const Duration(milliseconds: 100));
    }
    _processingQueue = false;
  }

  // ── Internal: Plan & Execute ────────────────────────────────────────────────
  static _Plan _planPronunciation({required String glyph, String? label}) {
    if (label != null) {
      final o = _overridePron(label);
      if (o != null && o.isNotEmpty) return _Plan.toKo(o);
    }
    if (label != null && _looksJapanese(label)) return _Plan.toJa(label);

    final consonantName = _name[glyph];
    if (consonantName != null) return _Plan.toKo(consonantName);

    final vowelKo = _vowelPronByGlyph[glyph];
    if (vowelKo != null && vowelKo.isNotEmpty) return _Plan.toKo(vowelKo);

    if (label != null && _looksLatin(label)) {
      final mapped = _latinToKoVowel[label.trim().toLowerCase()];
      if (mapped != null && mapped.isNotEmpty) return _Plan.toKo(mapped);
    }

    final text = (label?.trim().isNotEmpty == true) ? label! : glyph;
    return _Plan.toKo(text);
  }

  static Future<void> _executePlan(_Plan plan,
      {required bool interrupt}) async {
    if (plan.lang == _Lang.ko) {
      await _speakKo(plan.text, interrupt: interrupt);
    } else {
      await _speakJa(plan.text, interrupt: interrupt);
    }
  }

  // === Minimal clarity tweak: add sentence-final punctuation for very short utterances ===
  static String _prepareUtterance(String input,
      {required RegExp endPunct, required String period}) {
    final s = input.trim();
    if (s.isEmpty) return s;
    final veryShort = s.runes.length <= 2; // 한 글자(또는 매우 짧은 토큰)
    final hasPunct = endPunct.hasMatch(s);
    return (veryShort && !hasPunct) ? '$s$period' : s;
  }

  static Future<void> _speakKo(String text, {required bool interrupt}) async {
    if (text.trim().isEmpty) return;
    if (interrupt) await _tts.stop();
    await _tts.setLanguage(_koLocale);
    try {
      if (_koVoice != null) await _tts.setVoice(_koVoice!);
    } catch (_) {}
    try {
      await _tts.setSpeechRate(_rate);
    } catch (_) {}
    try {
      await _tts.setPitch(_pitch);
    } catch (_) {}
    try {
      await _tts.setVolume(_volume);
    } catch (_) {}

    // 한국어: 한 글자 등 매우 짧은 발화는 마침표를 붙여 끝소리 폐쇄 유도
    final out = _prepareUtterance(
      text,
      endPunct: RegExp(r'[.!?]$'),
      period: '.',
    );
    await _tts.speak(out);
  }

  static Future<void> _speakJa(String text, {required bool interrupt}) async {
    if (text.trim().isEmpty) return;
    if (interrupt) await _tts.stop();
    await _tts.setLanguage(_jaLocale);
    try {
      if (_jaVoice != null) await _tts.setVoice(_jaVoice!);
    } catch (_) {}
    try {
      await _tts.setSpeechRate(_rate);
    } catch (_) {}
    try {
      await _tts.setPitch(_pitch);
    } catch (_) {}
    try {
      await _tts.setVolume(_volume);
    } catch (_) {}

    // 일본어: 짧은 발화는 '。'를 붙여 경계 명확화
    final out =
        _prepareUtterance(text, endPunct: RegExp(r'[。！？]$'), period: '。');
    await _tts.speak(out);
  }

  // ── Utils ───────────────────────────────────────────────────────────────────
  static String? _overridePron(String s) {
    final key = s.trim().toLowerCase();
    return _labelOverrides[key];
  }

  static bool _looksJapanese(String s) {
    if (s.isEmpty) return false;
    for (final r in s.runes) {
      if ((r >= 0x3040 && r <= 0x309F) || (r >= 0x30A0 && r <= 0x30FF)) {
        return true;
      }
    }
    return false;
  }

  static bool _looksLatin(String s) {
    final t = s.trim();
    if (t.isEmpty) return false;
    final reg = RegExp(r'^[A-Za-z\-]+$');
    return reg.hasMatch(t);
  }
}

// ── Internal models ───────────────────────────────────────────────────────────
enum _JobKind { text, glyph }

class _TtsJob {
  final _JobKind kind;
  final String? text;
  final String? glyph;
  final String? label;

  _TtsJob.text(this.text)
      : kind = _JobKind.text,
        glyph = null,
        label = null;

  _TtsJob.glyph(this.glyph, {this.label})
      : kind = _JobKind.glyph,
        text = null;
}

enum _Lang { ko, ja }

class _Plan {
  final _Lang lang;
  final String text;
  const _Plan(this.lang, this.text);

  factory _Plan.toKo(String text) => _Plan(_Lang.ko, text);
  factory _Plan.toJa(String text) => _Plan(_Lang.ja, text);
}
