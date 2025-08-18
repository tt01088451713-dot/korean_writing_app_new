// lib/main.dart
import 'package:flutter/material.dart';

// Theme (색상 영구 저장 초기화)
import 'package:korean_writing_app_new/theme_state.dart';

// Screens
import 'package:korean_writing_app_new/screens/language_gate.dart';
import 'package:korean_writing_app_new/screens/home_hub.dart';                  // 커리큘럼 허브
import 'package:korean_writing_app_new/screens/jamo_hub.dart';                  // 자모 허브
import 'package:korean_writing_app_new/screens/coming_soon.dart';               // 임시 "준비중"
import 'package:korean_writing_app_new/screens/unit_1_1_consonantal_letter.dart'; // 자음자 단원
import 'package:korean_writing_app_new/screens/unit_1_2_vowel_letter.dart';     // 모음자 단원
import 'package:korean_writing_app_new/screens/writing_practice_page.dart';     // 쓰기 연습
import 'package:korean_writing_app_new/screens/qa_checklist_page.dart';         // ✅ QA 체크리스트(독립 화면)

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppTheme.init(); // 저장된 카드/글자 색 불러오기
  runApp(const AppRoot());
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal, // 취향에 맞게 변경 가능
      ),
      initialRoute: '/',
      routes: {
        // 0) 언어 선택
        '/': (_) => const LanguageGatePage(),

        // 1) 커리큘럼 허브 → 자모/글자/단어
        '/home': (_) => const CurriculumHubPage(),

        // 2) 자모 허브 → 자음자/모음자
        '/jamo': (_) => const JamoHubPage(),

        // 3) 자모 하위
        '/jamo/consonants': (_) => const UnitOverviewPage(),   // 자음자 단원
        '/jamo/vowels': (_) => const VowelOverviewPage(),      // 모음자 단원

        // 4) 글자/단어(임시)
        '/letters': (_) => const ComingSoonPage(),
        '/words': (_) => const ComingSoonPage(),

        // 5) ✅ 독립 QA 체크리스트
        '/qa': (_) => const QaChecklistPage(),
      },

      // 쓰기 연습으로 직접 진입: Navigator.pushNamed('/write', arguments: 'ㄱ')
      onGenerateRoute: (settings) {
        if (settings.name == '/write' && settings.arguments is String) {
          return MaterialPageRoute(
            builder: (_) =>
                WritingPracticePage(charGlyph: settings.arguments as String),
          );
        }
        return null;
      },

      // 알 수 없는 경로 → 커리큘럼 허브로
      onUnknownRoute: (_) =>
          MaterialPageRoute(builder: (_) => const CurriculumHubPage()),
    );
  }
}
