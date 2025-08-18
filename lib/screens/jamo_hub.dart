import 'package:flutter/material.dart';
import 'package:korean_writing_app_new/i18n/ui_texts.dart';
import 'package:korean_writing_app_new/theme_state.dart';

class JamoHubPage extends StatelessWidget {
  const JamoHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _JItem(UiText.t('menuConsonants'), 'ㄱ', '/jamo/consonants'),
      _JItem(UiText.t('menuVowels'),     'ㅏ', '/jamo/vowels'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(UiText.t('menuJamo')),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'lang') {
                Navigator.pushReplacementNamed(context, '/'); // 언어 선택으로
              } else if (v == 'theme') {
                _showColorSheet(context);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'lang',  child: Text(UiText.t('changeLanguage'))),
              PopupMenuItem(value: 'theme', child: Text(UiText.t('customizeColors'))),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                UiText.t('jamoIntro'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final it = items[i];
              return Card(
                clipBehavior: Clip.hardEdge,
                child: InkWell(
                  onTap: () => Navigator.pushNamed(context, it.route),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(it.glyph, style: const TextStyle(fontSize: 40)),
                        const SizedBox(height: 8),
                        Text(it.label,
                            style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _JItem {
  final String label;
  final String glyph;
  final String route;
  _JItem(this.label, this.glyph, this.route);
}

// ───────── 색상 설정 시트(허브와 동일) ─────────
void _showColorSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(UiText.t('customizeColors'),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
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
