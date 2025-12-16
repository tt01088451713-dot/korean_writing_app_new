// lib/main.dart
import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Theme
import 'package:korean_writing_app_new/theme_state.dart';

// Screens
import 'package:korean_writing_app_new/screens/language_gate.dart';
import 'package:korean_writing_app_new/screens/home_hub.dart';
import 'package:korean_writing_app_new/screens/jamo_hub.dart';
import 'package:korean_writing_app_new/screens/unit_1_1_consonantal_letter.dart';
import 'package:korean_writing_app_new/screens/unit_1_2_vowel_letter.dart';
import 'package:korean_writing_app_new/screens/writing_practice_page.dart';
import 'package:korean_writing_app_new/screens/letters_unit_page.dart';
import 'package:korean_writing_app_new/screens/letters_hub.dart';
import 'package:korean_writing_app_new/screens/letters_category_page.dart';

// 단어/문장 허브 & 레슨
import 'package:korean_writing_app_new/screens/words_hub.dart';
import 'package:korean_writing_app_new/screens/sentences_hub.dart';
import 'package:korean_writing_app_new/screens/words_lesson_page.dart';
import 'package:korean_writing_app_new/screens/sentences_lesson_page.dart';

// Settings
import 'package:korean_writing_app_new/screens/settings_page.dart';

// I18n
import 'package:korean_writing_app_new/i18n/language_state.dart';
import 'package:korean_writing_app_new/i18n/ui_texts.dart';

// 구매/광고 상태
import 'package:provider/provider.dart';
import 'package:korean_writing_app_new/ads/ads_purchase_state.dart';

// AdMob 서비스 (배너/보상형 초기화)
import 'package:korean_writing_app_new/services/admob_service.dart';

/// 글자 단원 인덱스/오버뷰 경로
class LettersPaths {
  static const String p21 = 'assets/data/letters/2_1_left_right_index.json';
  static const String p22 = 'assets/data/letters/2_2_hub_index.json';
  static const String p23 = 'assets/data/letters/2_3_hub_index.json';
  static const String p24 = 'assets/data/letters/2_4_hub_index.json';

  static const String ov21 = 'assets/data/letters/overviews/2_1_overview.json';
  static const String ov22 = 'assets/data/letters/overviews/2_2_overview.json';
  static const String ov23 = 'assets/data/letters/overviews/2_3_overview.json';
  static const String ov24 = 'assets/data/letters/overviews/2_4_overview.json';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 전역 에러 핸들러(릴리스 안전)
  FlutterError.onError = (FlutterErrorDetails d) {
    FlutterError.dumpErrorToConsole(d);
  };
  WidgetsBinding.instance.platformDispatcher.onError =
      (Object error, StackTrace stack) {
    debugPrint('UNCAUGHT: $error');
    debugPrintStack(stackTrace: stack);
    return true;
  };

  // 언어/테마 초기화
  await LanguageState.init();
  await AppTheme.init();

  // AdMob 서비스 초기화 (MobileAds.initialize + 보상형 선로딩)
  await AdmobService.instance.initialize();

  // AdsPurchaseState 전역 제공
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AdsPurchaseState>(
          // 싱글톤 인스턴스를 Provider에 등록
          create: (_) => AdsPurchaseState.I,
        ),
      ],
      child: const AppRoot(),
    ),
  );
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LanguageState.I,
      builder: (_, __) {
        final locale = _codeToLocale(LanguageState.I.code);

        return MaterialApp(
          title: UiText.t('appTitle'),
          debugShowCheckedModeBanner: false,
          scrollBehavior: const AppScrollBehavior(),
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.teal,
          ),
          locale: locale,
          supportedLocales: const [
            Locale('ko'),
            Locale('en'),
            Locale('ja'),
            Locale('zh'),
            Locale('vi'),
            Locale('fr'),
            Locale('de'),
            Locale('es'),
            Locale('ru'),
            Locale('mn'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],

          // ─────────────────────────────
          // 고정 라우트
          // ─────────────────────────────
          initialRoute: '/',
          routes: {
            '/': (_) => const LanguageGatePage(),
            '/home': (_) => const CurriculumHubPage(),

            // 설정 페이지 (routeName = '/settings')
            SettingsPage.routeName: (_) => const SettingsPage(),

            // 자모
            '/jamo': (_) => const JamoHubPage(),
            '/jamo/consonants': (_) => const UnitOverviewPage(),
            '/jamo/vowels': (_) => const VowelOverviewPage(),

            // 글자 최상위 허브
            '/letters': (_) => const LettersHubPage(),

            // 글자 카테고리 2.1 ~ 2.4
            '/letters/2_1': (_) => LettersCategoryPage(
              title: _t('letters.leftRight', '좌우 결합형'),
              overviewRef: LettersPaths.ov21,
              indexAssetPath: LettersPaths.p21,
              sectionId: '2_1',
            ),
            '/letters/2_2': (_) => LettersCategoryPage(
              title: _t('letters.topBottom', '상하 결합형'),
              overviewRef: LettersPaths.ov22,
              indexAssetPath: LettersPaths.p22,
              sectionId: '2_2',
            ),
            '/letters/2_3': (_) => LettersCategoryPage(
              title: _t('letters.lrTb', '좌우상하 결합형'),
              overviewRef: LettersPaths.ov23,
              indexAssetPath: LettersPaths.p23,
              sectionId: '2_3',
            ),
            '/letters/2_4': (_) => LettersCategoryPage(
              title: _t('letters.uhShape', 'ㅡ형'),
              overviewRef: LettersPaths.ov24,
              indexAssetPath: LettersPaths.p24,
              sectionId: '2_4',
            ),

            // 단어 / 문장 허브
            '/words': (_) => const WordsHubPage(),
            '/sentences': (_) => const SentencesHubPage(),

            // 단어 / 문장 레슨
            '/words/lesson': (_) => const WordsLessonPage(),
            '/sentences/lesson': (_) => const SentencesLessonPage(),
          },

          // ─────────────────────────────
          // 동적 라우트
          // ─────────────────────────────
          onGenerateRoute: (settings) {
            // 쓰기 연습(자모/글자/단어/문장)
            if (settings.name == '/write' || settings.name == '/practice') {
              final args = settings.arguments;
              final String glyph = args is String
                  ? args
                  : (args is Map && args['char'] is String
                  ? args['char'] as String
                  : (args is Map && args['charGlyph'] is String
                  ? args['charGlyph'] as String
                  : '가'));
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => WritingPracticePage(charGlyph: glyph),
              );
            }

            // 글자 유닛(인자는 내부에서 ModalRoute로 처리)
            if (settings.name == '/letters/unit') {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const LettersUnitPage(),
              );
            }

            return null;
          },

          onUnknownRoute: (_) =>
              MaterialPageRoute(builder: (_) => const CurriculumHubPage()),
        );
      },
    );
  }
}

/// 코드 문자열을 Locale로 변환
Locale _codeToLocale(String code) {
  if (code.isEmpty) return const Locale('ko');
  try {
    if (code.contains('-')) {
      final parts = code.split('-');
      if (parts.length >= 2) return Locale(parts[0], parts[1]);
      return Locale(parts[0]);
    }
    return Locale(code);
  } catch (_) {
    return const Locale('ko');
  }
}

/// i18n 키 조회(없으면 기본값)
String _t(String key, String fallback) {
  try {
    final s = UiText.t(key);
    if (s.trim().isNotEmpty) return s;
  } catch (_) {}
  return fallback;
}
