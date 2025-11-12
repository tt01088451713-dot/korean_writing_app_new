import 'package:flutter_tts/flutter_tts.dart';

const Map<String, String> kVoiceByLang = {
  'ko': 'ko-KR',
  'en': 'en-US',
  'zh': 'zh-CN',
  'ja': 'ja-JP',
  'vi': 'vi-VN',
  'fr': 'fr-FR',
  'es': 'es-ES',
  'ru': 'ru-RU',
  'mn': 'mn-MN', // 엔진에 없으면 기본으로 폴백됨
};

class Tts {
  Tts._();
  static final Tts I = Tts._();

  final FlutterTts _tts = FlutterTts();
  bool _inited = false;

  Future<void> _ensureInit() async {
    if (_inited) return;
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _inited = true;
  }

  Future<void> speak(String text, {String lang = 'ko'}) async {
    final t = text.trim();
    if (t.isEmpty) return;
    await _ensureInit();
    final voice = kVoiceByLang[lang];
    if (voice != null) {
      try {
        await _tts.setLanguage(voice);
      } catch (_) {}
    }
    await _tts.speak(t);
  }

  Future<void> stop() => _tts.stop();
}
