// lib/theme_state.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  static final cardColor  = ValueNotifier<Color>(Colors.teal);
  static final glyphColor = ValueNotifier<Color>(Colors.black);

  static const _kCard  = 'theme.cardColor';
  static const _kGlyph = 'theme.glyphColor';

  /// 앱 시작 시 저장된 색을 불러옵니다.
  static Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    final c = p.getInt(_kCard);
    final g = p.getInt(_kGlyph);
    if (c != null) cardColor.value  = Color(c);
    if (g != null) glyphColor.value = Color(g);
  }

  static Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kCard,  cardColor.value.value);
    await p.setInt(_kGlyph, glyphColor.value.value);
  }

  static void setCard(Color c)  { cardColor.value  = c; _save(); }
  static void setGlyph(Color c) { glyphColor.value = c; _save(); }

  static void reset() {
    cardColor.value  = Colors.teal;
    glyphColor.value = Colors.black;
    _save();
  }
}

/// 팔레트 색상 표시용 스와치
const List<Color> kThemeSwatches = <Color>[
  Colors.black, Colors.white, Colors.grey, Colors.brown,
  Colors.red, Colors.pink, Colors.deepOrange, Colors.orange,
  Colors.amber, Colors.yellow, Colors.lime, Colors.lightGreen, Colors.green,
  Colors.teal, Colors.cyan, Colors.lightBlue, Colors.blue,
  Colors.indigo, Colors.purple, Colors.deepPurple,
];

/// 카드 배경에 살짝 투명도 주기
const double kCardBgOpacity = 0.16;
