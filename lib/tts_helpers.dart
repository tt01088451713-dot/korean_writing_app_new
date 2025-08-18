// lib/tts_helpers.dart
import 'package:flutter_tts/flutter_tts.dart';

class AppTts {
  AppTts._();
  static final FlutterTts _tts = FlutterTts();
  static bool _inited = false;

  // 기억해두는 음성/로케일
  static Map<String, String>? _koVoice;
  static Map<String, String>? _jaVoice;
  static String _koLocale = 'ko-KR';
  static String _jaLocale = 'ja-JP';

  // ─────────────────────────────────────────────────────────────
  // ✅ 라벨(표시명) → 발음 예외 매핑 (여기에 추가로 확장하면 됨)
  // 예) UI에는 "arae-a" 그대로 두되, 발음은 "아래아"로
  static const Map<String, String> _labelOverrides = {
    'arae-a': '아래아',
    // 필요시 여기에 추가: 'arae-e': '아래에', ...
  };

  // 자음자: 기존 이름 매핑 (유지)
  static const Map<String, String> _name = {
    'ㄱ':'기역','ㄲ':'쌍기역','ㄴ':'니은','ㄷ':'디귿','ㄸ':'쌍디귿','ㄹ':'리을',
    'ㅁ':'미음','ㅂ':'비읍','ㅃ':'쌍비읍','ㅅ':'시옷','ㅆ':'쌍시옷',
    'ㅇ':'이응','ㅈ':'지읒','ㅉ':'쌍지읒','ㅊ':'치읓','ㅋ':'키읔',
    'ㅌ':'티읕','ㅍ':'피읖','ㅎ':'히읗',
    'ㄳ':'기역시옷','ㄵ':'니은지읒','ㄶ':'니은히읗','ㄺ':'리을기역','ㄻ':'리을미음',
    'ㄼ':'리을비읍','ㄽ':'리을시옷','ㄾ':'리을티읕','ㄿ':'리을피읖','ㅀ':'리을히읗','ㅄ':'비읍시옷',
  };

  // 모음자: 글리프 → 한국어 발음
  static const Map<String, String> _vowelPronByGlyph = {
    'ㅏ':'아','ㅑ':'야','ㅓ':'어','ㅕ':'여','ㅗ':'오','ㅛ':'요','ㅜ':'우','ㅠ':'유',
    'ㅡ':'으','ㅣ':'이',
    'ㅐ':'애','ㅒ':'얘','ㅔ':'에','ㅖ':'예',
    'ㅘ':'와','ㅙ':'왜','ㅚ':'외',
    'ㅝ':'워','ㅞ':'웨','ㅟ':'위',
    'ㅢ':'의',
    // 'ㆍ'는 설명 전용이라 발화하지 않음(원하시면 'ㆍ':'아래아' 추가 가능)
  };

  // 모음자: 라틴 라벨 → 한국어 발음 (영어 UI 등에서 철자 읽기 방지)
  static const Map<String, String> _latinToKoVowel = {
    'a':'아','ya':'야','eo':'어','yeo':'여','o':'오','yo':'요','u':'우','yu':'유',
    'eu':'으','i':'이',
    'ae':'애','yae':'얘','e':'에','ye':'예',
    'wa':'와','wae':'왜','oe':'외','wo':'워','we':'웨','wi':'위','ui':'의',
  };

  // ===== 초기화 =====
  static Future<void> _ensureInit() async {
    if (_inited) return;

    await _tts.awaitSpeakCompletion(true);
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);

    try {
      _tts.setStartHandler(() => print('[TTS] start'));
      _tts.setCompletionHandler(() => print('[TTS] complete'));
      _tts.setErrorHandler((msg) => print('[TTS] error: $msg'));
    } catch (_) {}

    final List<dynamic>? rawVoices = await _tts.getVoices;
    final List<dynamic>? languages = await _tts.getLanguages;

    print('[TTS] voices: $rawVoices');
    print('[TTS] languages: $languages');

    if (rawVoices != null) {
      for (final v in rawVoices) {
        final m = Map<String, String>.from(v as Map);
        final locale = (m['locale'] ?? '').toLowerCase();
        final name = (m['name'] ?? '').toLowerCase();

        if (_koVoice == null && (locale.startsWith('ko') || name.contains('korean'))) {
          _koVoice = m;
          if (m['locale'] != null) _koLocale = m['locale']!;
        }
        if (_jaVoice == null && (locale.startsWith('ja') || name.contains('japanese'))) {
          _jaVoice = m;
          if (m['locale'] != null) _jaLocale = m['locale']!;
        }
      }
    }

    // 기본은 한국어 음성
    await _tts.setLanguage(_koLocale);
    final koV = _koVoice; // 로컬 변수로 고정
    if (koV != null) {
      print('[TTS] use KO voice: $koV');
      try { await _tts.setVoice(koV); } catch (_) {}
    } else {
      print('[TTS] KO voice not found. Fallback to $_koLocale');
    }

    _inited = true;
  }

  // ===== 공개 API =====

  static Future<void> speak(String text) async {
    await _ensureInit();
    print('[TTS] speak: $text');
    await _tts.stop();
    await _tts.setLanguage(_koLocale);
    await _tts.speak(text);
  }

  /// glyph/label을 상황에 맞게 발화
  static Future<void> speakGlyphOrText(String glyph, {String? label}) async {
    await _ensureInit();

    // 0) 라벨 예외(arae-a → 아래아 등) 우선 처리
    if (label != null) {
      final o = _overridePron(label);
      if (o != null && o.isNotEmpty) {
        await _tts.stop();
        await _tts.setLanguage(_koLocale);
        await _tts.speak(o);
        return;
      }
    }

    // 1) 일본어 라벨이면 일본어로
    if (label != null && _looksJapanese(label)) {
      await _tts.stop();
      await _tts.setLanguage(_jaLocale);
      final jaV = _jaVoice; // 로컬 변수로 고정
      try { if (jaV != null) await _tts.setVoice(jaV); } catch (_) {}
      await _tts.speak(label);
      return;
    }

    // 2) 자음자 이름
    final consonantName = _name[glyph];
    if (consonantName != null) {
      await _tts.stop();
      await _tts.setLanguage(_koLocale);
      await _tts.speak(consonantName);
      return;
    }

    // 3) 모음자 (글리프 → 한국어 발음)
    final vowelKo = _vowelPronByGlyph[glyph];
    if (vowelKo != null && vowelKo.isNotEmpty) {
      await _tts.stop();
      await _tts.setLanguage(_koLocale);
      await _tts.speak(vowelKo);
      return;
    }

    // 4) 라틴 라벨 → 한국어 발음 매핑 (영어 UI의 철자 읽기 방지)
    if (label != null && _looksLatin(label)) {
      final mapped = _latinToKoVowel[label.trim().toLowerCase()];
      if (mapped != null && mapped.isNotEmpty) {
        await _tts.stop();
        await _tts.setLanguage(_koLocale);
        await _tts.speak(mapped);
        return;
      }
    }

    // 5) 폴백
    final text = (label?.trim().isNotEmpty == true) ? label! : glyph;
    await _tts.stop();
    await _tts.setLanguage(_koLocale);
    await _tts.speak(text);
  }

  // ===== 유틸 =====

  // 라벨 예외 변환 (대소문자/공백 보정)
  static String? _overridePron(String s) {
    final key = s.trim().toLowerCase();
    return _labelOverrides[key];
  }

  static bool _looksJapanese(String s) {
    if (s.isEmpty) return false;
    for (final r in s.runes) {
      if ((r >= 0x3040 && r <= 0x309F) || // Hiragana
          (r >= 0x30A0 && r <= 0x30FF)) { // Katakana
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
