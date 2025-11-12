// lib/screens/app_info_page.dart
import 'package:flutter/material.dart';

class AppInfoPage extends StatelessWidget {
  const AppInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About This App'),
      ),
      body: SafeArea( // ✅ 상단/하단 안전 영역 확보
        child: SingleChildScrollView( // ✅ 스크롤 지원 (작은 화면 대응)
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              // ───────── App Title ─────────
              Text(
                'Korean Writing App',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),

              // ───────── Developer & Author Info ─────────
              Text(
                'Developed by KST Lingua Studio',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 4),
              Text(
                'Educational contents designed by Prof. Sang-Tae Kim (Cheongju University)',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 6),
              Text(
                'Contact: support-kst@naver.com',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 4),
              Text(
                'Version 1.0.0 (2025)',
                style: TextStyle(fontSize: 16),
              ),

              SizedBox(height: 24),

              // ───────── App Description ─────────
              Text(
                'About:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                'This app helps learners of Korean practice writing and pronunciation '
                    'through structured lessons, stroke-by-stroke handwriting, and audio playback. '
                    'It supports multiple languages for multicultural learners around the world.',
                style: TextStyle(fontSize: 15, height: 1.4),
              ),

              SizedBox(height: 28),
              Divider(),
              SizedBox(height: 10),

              // ───────── Copyright ─────────
              Center(
                child: Text(
                  '© 2025 KST Lingua Studio & Prof. Sang-Tae Kim. All rights reserved.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
