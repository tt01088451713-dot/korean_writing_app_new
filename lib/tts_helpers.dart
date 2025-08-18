// lib/tts_helpers.dart
import 'package:flutter_tts/flutter_tts.dart';

class AppTts {
  AppTts._();
  static final FlutterTts _tts = FlutterTts();
  static bool _inited = false;

  static Future<void> _ensureInit() async {
    if (_inited) return;

    await _tts.awaitSpeakCompletion(true);
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);

    // 핸들러: 반환형이 void 이므로 await 금지
    try {
      _tts.setStartHandler(() => print('[TTS] start'));
      _tts.setCompletionHandler(() => print('[TTS] complete'));
      _tts.setErrorHandler((msg) => print('[TTS] error: $msg'));
    } catch (_) {}

    final List<dynamic>? rawVoices = await _tts.getVoices;
    final List<dynamic>? languages = await _tts.getLanguages;
    print('[TTS] voices: $rawVoices');
    print('[TTS] languages: $languages');

    Map<String, String>? koVoice;

    if (rawVoices != null) {
      for (final v in rawVoices) {
        final m = Map<String, String>.from(v as Map); // ← 정확 캐스팅
        final locale = (m['locale'] ?? '').toLowerCase();
        final name = (m['name'] ?? '').toLowerCase();
        if (locale.startsWith('ko') || name.contains('korean')) {
          koVoice = m;
          break;
        }
      }
    }

    if (koVoice != null) {
      print('[TTS] use KO voice: $koVoice');
      await _tts.setLanguage('ko-KR');
      await _tts.setVoice(koVoice); // Map<String,String>
    } else {
      final fallbackLocale = (languages != null && languages.isNotEmpty)
          ? languages.first as String
          : 'en-US';
      print('[TTS] KO voice not found. Fallback locale: $fallbackLocale');
      await _tts.setLanguage(fallbackLocale);
      if (rawVoices != null && rawVoices.isNotEmpty) {
        final firstVoice = Map<String, String>.from(rawVoices.first as Map);
        print('[TTS] use fallback voice: $firstVoice');
        await _tts.setVoice(firstVoice);
      }
    }

    _inited = true;
  }

  static Future<void> speak(String text) async {
    await _ensureInit();
    print('[TTS] speak: $text');
    await _tts.stop();
    await _tts.speak(text);
  }

  static const Map<String, String> _name = {
    'ㄱ':'기역','ㄲ':'쌍기역','ㄴ':'니은','ㄷ':'디귿','ㄸ':'쌍디귿','ㄹ':'리을',
    'ㅁ':'미음','ㅂ':'비읍','ㅃ':'쌍비읍','ㅅ':'시옷','ㅆ':'쌍시옷',
    'ㅇ':'이응','ㅈ':'지읒','ㅉ':'쌍지읒','ㅊ':'치읓','ㅋ':'키읔',
    'ㅌ':'티읕','ㅍ':'피읖','ㅎ':'히읗',
    'ㄳ':'기역시옷','ㄵ':'니은지읒','ㄶ':'니은히읗','ㄺ':'리을기역','ㄻ':'리을미음',
    'ㄼ':'리을비읍','ㄽ':'리을시옷','ㄾ':'리을티읕','ㄿ':'리을피읖','ㅀ':'리을히읗','ㅄ':'비읍시옷',
  };

  /// 자모면 이름으로, 없으면 label 우선, 그래도 없으면 원문자
  static Future<void> speakGlyphOrText(String glyph, {String? label}) async {
    final text = _name[glyph] ?? label ?? glyph;
    await speak(text);
  }
}
