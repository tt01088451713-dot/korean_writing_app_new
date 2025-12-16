// lib/screens/home_hub.dart
import 'package:flutter/material.dart';
import 'package:korean_writing_app_new/i18n/ui_texts.dart';
import 'package:korean_writing_app_new/theme_state.dart';
import 'package:korean_writing_app_new/screens/app_info_page.dart';

class CurriculumHubPage extends StatelessWidget {
  const CurriculumHubPage({super.key});

  String _t(String key, String fallback) {
    try {
      final s = UiText.t(key);
      if (s.trim().isNotEmpty && s != key) return s;
    } catch (_) {}
    return fallback;
  }

  void _safePushNamed(BuildContext context, String route) {
    try {
      Navigator.pushNamed(context, route);
    } catch (e) {
      debugPrint('Navigation error to $route: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('navError', '이동 중 오류가 발생했습니다.')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = <_HubItem>[
      _HubItem(_t('menuJamo', '자모'), Icons.grid_on, '/jamo'),
      _HubItem(_t('menuLetters', '글자'), Icons.view_module, '/letters'),
      _HubItem(_t('menuWords', '단어'), Icons.text_fields, '/words'),
      _HubItem(_t('menuSentences', '문장'), Icons.short_text, '/sentences'),
      _HubItem(_t('menuRemoveAds', '광고 제거'), Icons.block, '__remove_ads__'),
      _HubItem(_t('appInfo', 'App Info'), Icons.info_outline, '__app_info__'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('curriculum', '학습 선택')),
        actions: [
          // ✅ 세 점 대신 톱니바퀴 모양으로 표시되는 PopupMenu 하나만 사용
          PopupMenuButton<String>(
            tooltip: _t('settings', '설정'),
            icon: const Icon(Icons.settings),
            onSelected: (v) {
              if (v == 'lang') {
                Navigator.pushReplacementNamed(context, '/');
              } else if (v == 'theme') {
                _showColorSheet(context);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'lang',
                child: Text(_t('changeLanguage', '언어 변경')),
              ),
              PopupMenuItem(
                value: 'theme',
                child: Text(_t('customizeColors', '색상 커스터마이즈')),
              ),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final cross = w >= 1100
              ? 4
              : w >= 750
              ? 3
              : 2;
          final ratio = w >= 1100
              ? 1.15
              : w >= 750
              ? 1.12
              : 1.08;

          final double labelSize =
          w >= 1100 ? 22.0 : (w >= 750 ? 20.0 : 18.0);

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cross,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: ratio,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final it = items[i];
              return ValueListenableBuilder<Color>(
                valueListenable: AppTheme.cardColor,
                builder: (_, cardC, __) {
                  return ValueListenableBuilder<Color>(
                    valueListenable: AppTheme.glyphColor,
                    builder: (_, glyphC, __) {
                      return Semantics(
                        button: true,
                        label: it.label,
                        child: Card(
                          color: cardC.withValues(alpha: kCardBgOpacity),
                          clipBehavior: Clip.hardEdge,
                          child: InkWell(
                            onTap: () {
                              if (it.route == '__app_info__' ||
                                  it.route == '__remove_ads__') {
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const AppInfoPage(),
                                    ),
                                  );
                                });
                              } else {
                                _safePushNamed(context, it.route);
                              }
                            },
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(it.icon, size: 40, color: glyphC),
                                  const SizedBox(height: 10),
                                  Text(
                                    it.label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                      color: glyphC,
                                      fontSize: labelSize,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _HubItem {
  final String label;
  final IconData icon;
  final String route;
  const _HubItem(this.label, this.icon, this.route);
}

void _showRemoveAdsDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(
          UiText.t('menuRemoveAds') != 'menuRemoveAds'
              ? UiText.t('menuRemoveAds')
              : '광고 제거',
        ),
        content: Text(
          UiText.t('removeAdsBody') != 'removeAdsBody'
              ? UiText.t('removeAdsBody')
              : '광고 제거 결제 기능은 결제 프로필 인증 후 활성화됩니다.\n\n'
              '정식 버전에서는 이 버튼을 통해 광고 제거(인앱 결제)를 진행할 수 있습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              UiText.t('removeAdsOk') != 'removeAdsOk'
                  ? UiText.t('removeAdsOk')
                  : '확인',
            ),
          ),
        ],
      );
    },
  );
}

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
