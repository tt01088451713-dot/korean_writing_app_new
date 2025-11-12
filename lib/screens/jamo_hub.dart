// lib/screens/jamo_hub.dart
import 'package:flutter/material.dart';
import 'package:korean_writing_app_new/i18n/ui_texts.dart';
import 'package:korean_writing_app_new/theme_state.dart';

class JamoHubPage extends StatelessWidget {
  const JamoHubPage({super.key});

  double _scale(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return (w / 800).clamp(0.9, 1.25);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final s = _scale(context);

    // 설명 텍스트(개요) 스타일
    final descStyle = t.textTheme.bodyLarge?.copyWith(
      fontSize: (15.5 * s).clamp(14, 18).toDouble(),
      height: 1.45,
      color: t.colorScheme.onSurface.withValues(alpha: 0.92),
      fontWeight: FontWeight.w500,
    );

    // 카드 라벨/글리프 – 반응형 확대
    final labelFont = (16 * s).clamp(15, 20).toDouble();
    final glyphFont = (56 * s).clamp(44, 68).toDouble();

    final items = <_JItem>[
      _JItem(
        (UiText.t('menuConsonants').trim().isEmpty
            ? '자음자'
            : UiText.t('menuConsonants')),
        'ㄱ',
        '/jamo/consonants',
      ),
      _JItem(
        (UiText.t('menuVowels').trim().isEmpty
            ? '모음자'
            : UiText.t('menuVowels')),
        'ㅏ',
        '/jamo/vowels',
      ),
    ];

    final hubTitle =
        (UiText.t('menuJamo').trim().isEmpty ? '자모' : UiText.t('menuJamo'));
    final hubDesc = UiText.t('jamoIntro'); // 개요 본문만 사용(제목은 AppBar와 중복 제거)

    return Scaffold(
      appBar: AppBar(title: Text(hubTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // 상단 설명 블록 (제목 출력 제거: AppBar와 중복 방지)
          if (hubDesc.trim().isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: t.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(hubDesc, style: descStyle),
            ),
          if (hubDesc.trim().isNotEmpty) const SizedBox(height: 16),

          // 반응형 카드 그리드
          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final cross = w >= 1100
                  ? 3
                  : w >= 750
                      ? 2
                      : 1;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cross,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 16 / 10,
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () {
                                  try {
                                    Navigator.pushNamed(context, it.route);
                                  } catch (_) {}
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        it.glyph,
                                        style: TextStyle(
                                          fontSize: glyphFont,
                                          fontWeight: FontWeight.w800,
                                          height: 1.0,
                                          color: glyphC.withValues(alpha: 0.95),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        it.label,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            t.textTheme.titleMedium?.copyWith(
                                          fontSize: labelFont,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.15,
                                          color: t.colorScheme.onSurface
                                              .withValues(alpha: 0.96),
                                        ),
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
        ],
      ),

      // 기존 테마/언어 액션 유지
      floatingActionButton: PopupMenuButton<String>(
        onSelected: (v) {
          if (v == 'lang') {
            // 언어 변경 게이트로 이동 (안전 폴백)
            try {
              Navigator.pushReplacementNamed(context, '/');
            } catch (_) {}
          } else if (v == 'theme') {
            _showColorSheet(context);
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(value: 'lang', child: Text(UiText.t('changeLanguage'))),
          PopupMenuItem(
              value: 'theme', child: Text(UiText.t('customizeColors'))),
        ],
        child: const FloatingActionButton(
          onPressed: null,
          child: Icon(Icons.tune),
        ),
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

// ───────── 색상 설정 시트(기존 유지) ─────────
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
