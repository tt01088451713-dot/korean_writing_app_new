// lib/theme_state.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ---------------------------------------------------------------------------
///  AppTheme: 색상 상태 저장/복원 (기존 유지)
/// ---------------------------------------------------------------------------
class AppTheme {
  static final cardColor = ValueNotifier<Color>(Colors.teal);
  static final glyphColor = ValueNotifier<Color>(Colors.black);

  static const _kCard = 'theme.cardColor';
  static const _kGlyph = 'theme.glyphColor';

  /// 앱 시작 시 저장된 색을 불러옵니다.
  static Future<void> init() async {
    try {
      final p = await SharedPreferences.getInstance();
      final c = p.getInt(_kCard);
      final g = p.getInt(_kGlyph);
      if (c != null) cardColor.value = Color(c);
      if (g != null) glyphColor.value = Color(g);
    } catch (_) {
      // 안정성 우선: 실패해도 기본값으로 동작
    }
  }

  static Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt(_kCard, cardColor.value.value);
      await p.setInt(_kGlyph, glyphColor.value.value);
    } catch (_) {
      // 저장 실패 시에도 앱 동작에는 영향 없도록 무시
    }
  }

  static void setCard(Color c) {
    cardColor.value = c;
    _save();
  }

  static void setGlyph(Color c) {
    glyphColor.value = c;
    _save();
  }

  static void reset() {
    cardColor.value = Colors.teal;
    glyphColor.value = Colors.black;
    _save();
  }
}

/// 팔레트 색상 표시용 스와치
const List<Color> kThemeSwatches = <Color>[
  Colors.black,
  Colors.white,
  Colors.grey,
  Colors.brown,
  Colors.red,
  Colors.pink,
  Colors.deepOrange,
  Colors.orange,
  Colors.amber,
  Colors.yellow,
  Colors.lime,
  Colors.lightGreen,
  Colors.green,
  Colors.teal,
  Colors.cyan,
  Colors.lightBlue,
  Colors.blue,
  Colors.indigo,
  Colors.purple,
  Colors.deepPurple,
];

/// 카드 배경에 살짝 투명도 주기
const double kCardBgOpacity = 0.16;

/// ---------------------------------------------------------------------------
///  ThemeState: 전역 테마(안정/가독성 강화)
///   - Material 3 + Seed Color 기반 ColorScheme
///   - 전역 cardTheme 설정은 **제거**(SDK 버전차 충돌 방지)
/// ---------------------------------------------------------------------------
class ThemeState {
  static ThemeData current({Brightness brightness = Brightness.light}) {
    return _buildTheme(
      seed: AppTheme.cardColor.value,
      glyph: AppTheme.glyphColor.value,
      brightness: brightness,
    );
  }

  static ThemeData light() => current(brightness: Brightness.light);
  static ThemeData dark() => current(brightness: Brightness.dark);

  static ThemeData _buildTheme({
    required Color seed,
    required Color glyph,
    required Brightness brightness,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    // 가독성 위주의 보수적 타이포그래피
    final textTheme = base.textTheme.copyWith(
      bodyLarge: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.w600, height: 1.25),
      bodyMedium: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600, height: 1.25),
      bodySmall: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w500, height: 1.25),
      titleLarge: const TextStyle(
          fontSize: 20, fontWeight: FontWeight.w700, height: 1.22),
      titleMedium: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w700, height: 1.22),
      titleSmall: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w700, height: 1.22),
      labelLarge: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w700, height: 1.20),
      labelMedium: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w700, height: 1.15),
    );

    final appBarTheme = AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
      iconTheme: IconThemeData(color: scheme.onSurface),
    );

    final listTileTheme = ListTileThemeData(
      iconColor: scheme.onSurface,
      textColor: scheme.onSurface,
    );

    final iconTheme = IconThemeData(color: glyph);

    final inputDecorationTheme = InputDecorationTheme(
      border: const OutlineInputBorder(),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: appBarTheme,
      // ⚠ 전역 cardTheme 설정은 버전별 타입 차이로 충돌 가능 → 미설정
      listTileTheme: listTileTheme,
      iconTheme: iconTheme,
      inputDecorationTheme: inputDecorationTheme,
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
