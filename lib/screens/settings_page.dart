// lib/screens/settings_page.dart
import 'package:flutter/material.dart';
import 'package:korean_writing_app_new/i18n/ui_texts.dart';
import 'package:korean_writing_app_new/theme_state.dart';
import 'package:korean_writing_app_new/screens/app_info_page.dart';

class SettingsPage extends StatelessWidget {
  static const String routeName = '/settings'; // ← 이 줄 추가
  const SettingsPage({super.key});

  // i18n 안전 폴백
  String _t(String key, String fallback) {
    try {
      final s = UiText.t(key);
      if (s.trim().isNotEmpty && s != key) return s;
    } catch (_) {}
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('settings.title', 'Settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ───── 언어 변경 ─────
          Card(
            child: ListTile(
              leading: const Icon(Icons.language),
              title: Text(_t('settings.changeLanguage', 'Change language')),
              subtitle: Text(
                _t(
                  'settings.changeLanguageSub',
                  'Go back to the language selection screen.',
                ),
              ),
              onTap: () {
                // 언어 선택 화면으로 돌아가기 (게이트 화면)
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ),
          const SizedBox(height: 12),

          // ───── 색상 커스터마이즈 ─────
          Card(
            child: ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: Text(_t('settings.colors', 'Customize colors')),
              subtitle: Text(
                _t(
                  'settings.colorsSub',
                  'Change the card/background and letter colors.',
                ),
              ),
              onTap: () => _showColorSheet(context),
            ),
          ),
          const SizedBox(height: 12),

          // ───── 광고/인앱 안내 (실제 결제는 AppInfo에서) ─────
          Card(
            child: ListTile(
              leading: const Icon(Icons.block),
              title: Text(_t('settings.ads', 'Ads & Remove Ads')),
              subtitle: Text(
                _t(
                  'settings.adsSub',
                  'To remove ads, open the App Info page and use the Remove Ads option.',
                ),
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AppInfoPage(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ───────── 색상 설정 시트 (home_hub와 동일 패턴) ─────────
void _showColorSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              UiText.t('customizeColors') != 'customizeColors'
                  ? UiText.t('customizeColors')
                  : '색상 커스터마이즈',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  UiText.t('cardColor') != 'cardColor'
                      ? UiText.t('cardColor')
                      : '카드 색상',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in kThemeSwatches)
                        GestureDetector(
                          onTap: () => AppTheme.setCard(c),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  UiText.t('letterColor') != 'letterColor'
                      ? UiText.t('letterColor')
                      : '글자 색상',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in kThemeSwatches)
                        GestureDetector(
                          onTap: () => AppTheme.setGlyph(c),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: AppTheme.reset,
                child: Text(
                  UiText.t('reset') != 'reset' ? UiText.t('reset') : '초기화',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
