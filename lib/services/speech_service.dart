// lib/services/speech_service.dart
import 'package:flutter_tts/flutter_tts.dart';

/// 표준 자모 명칭(필요 시 확장)
const Map<String, String> kJamoNamesKo = {
  "ㄱ": "기역",
  "ㄲ": "쌍기역",
  "ㄴ": "니은",
  "ㄷ": "디귿",
  "ㄸ": "쌍디귿",
  "ㄹ": "리을",
  "ㅁ": "미음",
  "ㅂ": "비읍",
  "ㅃ": "쌍비읍",
  "ㅅ": "시옷",
  "ㅆ": "쌍시옷",
  "ㅇ": "이응",
  "ㅈ": "지읒",
  "ㅉ": "쌍지읒",
  "ㅊ": "치읓",
  "ㅋ": "키읔",
  "ㅌ": "티읕",
  "ㅍ": "피읖",
  "ㅎ": "히읗",
  "ㅏ": "아",
  "ㅐ": "애",
  "ㅑ": "야",
  "ㅒ": "얘",
  "ㅓ": "어",
  "ㅔ": "에",
  "ㅕ": "여",
  "ㅖ": "예",
  "ㅗ": "오",
  "ㅘ": "와",
  "ㅙ": "왜",
  "ㅚ": "외",
  "ㅛ": "요",
  "ㅜ": "우",
  "ㅝ": "워",
  "ㅞ": "웨",
  "ㅟ": "위",
  "ㅠ": "유",
  "ㅡ": "으",
  "ㅢ": "의",
  "ㅣ": "이"
};

class SpeechService {
  SpeechService._();
  static final instance = SpeechService._();

  final _tts = FlutterTts();

  /// 앱 시작 시 1회 호출
  Future<void> init({
    String locale = 'ko-KR',
    double rate = 0.5, // 0.0 ~ 1.0 (느림 ~ 빠름)
    double pitch = 1.0, // 0.5 ~ 2.0
    double volume = 1.0, // 0.0 ~ 1.0
  }) async {
    await _tts.setLanguage(locale);
    await _tts.setSpeechRate(rate);
    await _tts.setPitch(pitch);
    await _tts.setVolume(volume);
    // iOS/Android별 추가 세팅이 필요하면 여기서 분기 가능
  }

  /// 현재 말하기 중지
  Future<void> stop() => _tts.stop();

  /// 자모 단원: 자모 '명칭'을 한국어로 발화 (현행 유지)
  Future<void> speakJamo(String jamo) async {
    final text = kJamoNamesKo[jamo] ?? jamo;
    await _tts.stop();
    await _tts.speak(text);
  }

  /// 글자(2.x) 단원: 음절 자체를 그대로 발화 (mp3 사용 안 함)
  Future<void> speakGlyph(String glyph) async {
    await _tts.stop();
    await _tts.speak(glyph);
  }

  /// 문장/단어 낭독용 (필요 시)
  Future<void> speakText(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  /// 옵션 변경(예: 화면 전환 시 로케일만 교체)
  Future<void> configure(
      {String? locale, double? rate, double? pitch, double? volume}) async {
    if (locale != null) await _tts.setLanguage(locale);
    if (rate != null) await _tts.setSpeechRate(rate);
    if (pitch != null) await _tts.setPitch(pitch);
    if (volume != null) await _tts.setVolume(volume);
  }
}
