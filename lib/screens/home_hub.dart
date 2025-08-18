// lib/screens/home_hub.dart
import 'package:flutter/material.dart';
import 'package:korean_writing_app_new/i18n/ui_texts.dart';
import 'package:korean_writing_app_new/theme_state.dart';

class CurriculumHubPage extends StatelessWidget {
  const CurriculumHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    // i18n 키가 없을 때 깔끔한 폴백(표시: 'QA')
    final qaLabel = (() {
      final s = UiText.t('qaChecklist');
      return (s == 'qaChecklist') ? 'QA' : s;
    })();

    final items = <_HubItem>[
      _HubItem(UiText.t('menuJamo'), Icons.grid_on, '/jamo'),
      _HubItem(UiText.t('menuLetters'), Icons.view_module, '/letters'),
      _HubItem(UiText.t('menuWords'), Icons.text_fields, '/words'),
      // ✅ QA 체크리스트 독립 화면
      _HubItem(qaLabel, Icons.fact_check, '/qa'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(UiText.t('curriculum')),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'lang') {
                Navigator.pushReplacementNamed(context, '/'); // 언어 선택으로
              } else if (v == 'theme') {
                _showColorSheet(context);
              } else if (v == 'qa') {
                Navigator.pushNamed(context, '/qa'); // ✅ QA로 이동
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'lang',
                child: Text(UiText.t('changeLanguage')),
              ),
              PopupMenuItem(
                value: 'theme',
                child: Text(UiText.t('customizeColors')),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'qa',
                child: Text(qaLabel),
              ),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final cross = w >= 1100 ? 4 : w >= 750 ? 3 : 2; // 반응형 컬럼 수

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cross,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
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
                      return Card(
                        color: cardC.withOpacity(kCardBgOpacity),
                        clipBehavior: Clip.hardEdge,
                        child: InkWell(
                          onTap: () => Navigator.pushNamed(context, it.route),
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
                                      ?.copyWith(color: glyphC),
                                  textAlign: TextAlign.center,
                                ),
                              ],
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
  _HubItem(this.label, this.icon, this.route);
}

// ───────── 색상 설정 시트 ─────────
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
              UiText.t('customizeColors'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(UiText.t('cardColor')),
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
                Text(UiText.t('letterColor')),
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
                child: Text(UiText.t('reset')),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
