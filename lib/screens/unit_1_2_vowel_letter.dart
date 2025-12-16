// lib/screens/unit_1_2_vowel_letter.dart
import 'package:flutter/material.dart';

// 데이터 로더 / TTS / 쓰기 연습
import 'package:korean_writing_app_new/data_loader/data_loader.dart';
import 'package:korean_writing_app_new/tts_helpers.dart';
import 'package:korean_writing_app_new/screens/writing_practice_page.dart';

// i18n
import 'package:korean_writing_app_new/i18n/language_state.dart';
import 'package:korean_writing_app_new/i18n/i18n_utils.dart';
import 'package:korean_writing_app_new/i18n/ui_texts.dart';

// 테마 & 가이드 에셋
import 'package:korean_writing_app_new/theme_state.dart';
import 'package:korean_writing_app_new/data_loader/stroke_assets.dart';

// ✅ 공용 배너 광고 위젯
import 'package:korean_writing_app_new/ads/banner_ad_widget.dart';

/// 모음자 데이터 경로
const String kUnitAsset = 'assets/data/1_2_vowel_letter.json';

/// Map<{ko:,en:,...}>에서 현재 언어 우선 텍스트 선택
String _pickI18nFromMap(Map m) {
  final code = LanguageState.I.code.toLowerCase();
  final base = code.split('-').first;
  final cands = <String>[code, base, 'en', 'ko'];
  for (final k in cands) {
    final v = m[k];
    if (v is String && v.trim().isNotEmpty) return v;
  }
  for (final v in m.values) {
    if (v is String && v.trim().isNotEmpty) return v;
  }
  return '';
}

/// 파트/서브파트 설명: description_* 또는 description(Map) 우선
String _pickPartDesc(Map p) {
  final d1 = pickI18n(p, 'description');
  if (d1.isNotEmpty) return d1;

  final raw = p['description'];
  if (raw is Map) {
    final d2 = _pickI18nFromMap(raw);
    if (d2.isNotEmpty) return d2;
  }
  return '';
}

/// 파트 제목: title_* 또는 title(Map) → groupKey(UiText) → part(문자)
String _partTitleOf(Map p) {
  final t1 = pickI18n(p, 'title');
  if (t1.isNotEmpty) return t1;

  final raw = p['title'];
  if (raw is Map) {
    final t2 = _pickI18nFromMap(raw);
    if (t2.isNotEmpty) return t2;
  }

  final gk = p['groupKey'];
  if (gk is String && gk.isNotEmpty) {
    final label = UiText.t(gk);
    if (label.isNotEmpty && label != gk) return label;
  }

  final s = p['part'];
  if (s is String && s.isNotEmpty) return s;

  return 'Section';
}

/// 카드 하단 설명: origin_* 또는 origin(Map) → principle / principle_translation(Map)
String _pickOrigin(Map item) {
  final o1 = pickI18n(item, 'origin');
  if (o1.isNotEmpty) return o1;

  final rawOrigin = item['origin'];
  if (rawOrigin is Map) {
    final o2 = _pickI18nFromMap(rawOrigin);
    if (o2.isNotEmpty) return o2;
  }

  final pr = item['principle'];
  if (pr is String && pr.trim().isNotEmpty) return pr;

  final prTr = item['principle_translation'];
  if (prTr is Map) {
    final tr = _pickI18nFromMap(prTr);
    if (tr.isNotEmpty) return tr;
  }
  return '';
}

/// 제목 정규화: 끝이 ' 단원'이면 제거
String _normalizeTitle(String s) {
  final t = s.trim();
  const suffix = ' 단원';
  return t.endsWith(suffix) ? t.substring(0, t.length - suffix.length) : t;
}

/// 정규화 후 같은지 비교
bool _sameTitle(String a, String b) =>
    _normalizeTitle(a).trim() == _normalizeTitle(b).trim();

class VowelOverviewPage extends StatefulWidget {
  const VowelOverviewPage({super.key});
  @override
  State<VowelOverviewPage> createState() => _VowelOverviewPageState();
}

class _VowelOverviewPageState extends State<VowelOverviewPage> {
  late Future<Map<String, dynamic>> future;

  // 반응형 스케일(가독성 강화, 보수적 범위)
  double _scale(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return (w / 900).clamp(0.95, 1.25);
  }

  @override
  void initState() {
    super.initState();
    future = loadJsonAsset(kUnitAsset);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = _scale(context);

    // ── 공통 텍스트 스타일(선명도/대비 향상) ──
    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      fontSize: (22 * s).clamp(20, 26).toDouble(),
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurface,
      height: 1.25,
    );
    final subtitleStyle = theme.textTheme.titleMedium?.copyWith(
      fontSize: (16 * s).clamp(15, 18).toDouble(),
      color: theme.colorScheme.onSurface.withValues(alpha: .92),
      fontWeight: FontWeight.w600,
    );
    final overviewStyle = theme.textTheme.bodyLarge?.copyWith(
      fontSize: (15.5 * s).clamp(14, 18).toDouble(),
      height: 1.5,
      color: theme.colorScheme.onSurface.withValues(alpha: .95),
      fontWeight: FontWeight.w500,
    );
    final sectionTitleStyle = theme.textTheme.titleMedium?.copyWith(
      fontSize: (18 * s).clamp(17, 22).toDouble(),
      fontWeight: FontWeight.w800,
      color: theme.colorScheme.onSurface.withValues(alpha: .98),
    );
    final subSectionTitleStyle = theme.textTheme.titleSmall?.copyWith(
      fontSize: (16 * s).clamp(15, 18).toDouble(),
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurface.withValues(alpha: .96),
    );
    final sectionDescStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: (14.5 * s).clamp(13, 17).toDouble(),
      height: 1.45,
      color: theme.colorScheme.onSurface.withValues(alpha: .9),
    );
    final subSectionDescStyle = theme.textTheme.bodySmall?.copyWith(
      fontSize: (13.5 * s).clamp(12, 16).toDouble(),
      height: 1.4,
      color: theme.colorScheme.onSurface.withValues(alpha: .88),
    );

    return FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text(UiText.t('menuVowels'))),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText('Error:\n${snap.error}'),
            ),
          );
        }

        final data = snap.data!;
        final rawTitle = pickI18n(data, 'title');
        final subtitle = pickI18n(data, 'subtitle');

        // AppBar용 실제 제목(정규화)
        final appBarTitle = _normalizeTitle(
          rawTitle.isNotEmpty ? rawTitle : UiText.t('menuVowels'),
        );

        // overview_* 또는 overview(Map) 또는 introduction_ko 폴백
        String overview = pickI18n(data, 'overview');
        if (overview.isEmpty) {
          final raw = data['overview'];
          if (raw is Map) overview = _pickI18nFromMap(raw);
        }
        if (overview.isEmpty) {
          final koIntro = data['introduction_ko'];
          if (koIntro is String) overview = koIntro;
        }

        final parts = (data['parts'] as List?) ?? const [];

        return Scaffold(
          appBar: AppBar(
            title: Text(appBarTitle),
            actions: [
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'lang') {
                    try {
                      // 언어 선택 페이지 (앱 라우팅 규칙에 맞게 변경 가능)
                      Navigator.pushReplacementNamed(context, '/');
                    } catch (_) {}
                  } else if (v == 'theme') {
                    _showColorSheet(context);
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
                ],
              ),
            ],
          ),
          backgroundColor: theme.colorScheme.surface,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                // 제목 중복 방지: AppBar와 같으면 본문 타이틀 숨김
                if (rawTitle.isNotEmpty && !_sameTitle(rawTitle, appBarTitle))
                  Text(rawTitle, style: titleStyle),

                if (subtitle.isNotEmpty) ...[
                  if (rawTitle.isNotEmpty &&
                      !_sameTitle(rawTitle, appBarTitle))
                    const SizedBox(height: 4),
                  Text(subtitle, style: subtitleStyle),
                ],

                if (overview.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(overview, style: overviewStyle),
                ],
                const SizedBox(height: 12),
                if (parts.isEmpty) Text(UiText.t('noItems')),

                // 파트 렌더링
                ...parts.map((pAny) {
                  final p = pAny as Map;
                  final partTitle = _partTitleOf(p);
                  final partDesc = _pickPartDesc(p);
                  final chars = (p['chars'] as List?) ?? const [];
                  final subparts = (p['subparts'] as List?) ?? const [];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Text(partTitle, style: sectionTitleStyle),
                      if (partDesc.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(partDesc, style: sectionDescStyle),
                      ],
                      const SizedBox(height: 8),
                      if (subparts.isEmpty && chars.isNotEmpty)
                        _GlyphGrid(chars, scale: s),
                      ...subparts.map((spAny) {
                        final sp = spAny as Map;
                        final subTitle = _partTitleOf(sp);
                        final subDesc = _pickPartDesc(sp);
                        final subChars = (sp['chars'] as List?) ?? const [];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            Text(subTitle, style: subSectionTitleStyle),
                            if (subDesc.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(subDesc, style: subSectionDescStyle),
                            ],
                            const SizedBox(height: 6),
                            _GlyphGrid(subChars, scale: s),
                          ],
                        );
                      }),
                      const SizedBox(height: 10),
                      const Divider(height: 24),
                    ],
                  );
                }),
              ],
            ),
          ),

          // ─────────────────────────────
          // 하단 배너 광고 – 공용 BannerAdArea 사용
          // (광고 제거 여부는 BannerAdArea 내부에서 처리)
          // ─────────────────────────────
          bottomNavigationBar: const SafeArea(
            top: false,
            child: BannerAdArea(),
          ),
        );
      },
    );
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
}

class _GlyphGrid extends StatelessWidget {
  const _GlyphGrid(this.items, {required this.scale});
  final List items;
  final double scale;

  bool _isAraeA(String glyph) => glyph == 'ㆍ';

  int _calcCols(double w) {
    if (w >= 1200) return 8;
    if (w >= 1024) return 7;
    if (w >= 900) return 6;
    if (w >= 700) return 5;
    if (w >= 520) return 4;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Text(UiText.t('noItems')),
      );
    }

    final theme = Theme.of(context);
    // 자음자와 비슷한 크기로 살짝 줄여 여백 확보
    final glyphFont = (28 * scale).clamp(24, 34).toDouble();
    final nameFont = (14 * scale).clamp(13, 16).toDouble();
    final originFont = (12.5 * scale).clamp(12, 14.5).toDouble();

    return LayoutBuilder(
      builder: (context, c) {
        final cols = _calcCols(c.maxWidth);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 4),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            childAspectRatio: 0.9,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final it = items[i];

            String glyph = '';
            String nameLabel = '';
            String origin = '';

            if (it is Map) {
              glyph =
                  (it['char'] ?? it['glyph'] ?? it['text'] ?? '').toString();

              // 이름: name_* 또는 name(Map)
              nameLabel = pickI18n(it, 'name');
              if (nameLabel.isEmpty) {
                final rawName = it['name'];
                if (rawName is Map) nameLabel = _pickI18nFromMap(rawName);
              }

              // 출처/원리: origin_* / origin(Map) / principle / principle_translation(Map)
              origin = _pickOrigin(it);

              if (glyph.isEmpty) {
                glyph = '${it['glyph'] ?? it['char'] ?? it['text'] ?? it}';
              }
            } else {
              glyph = '$it';
            }

            final guide = StrokeAssets.get(glyph);
            final hasGuide = guide != null;
            // hasGuide는 현재 “가이드 존재 여부” 확인용 (레이아웃 영향 없음)

            return ValueListenableBuilder<Color>(
              valueListenable: AppTheme.cardColor,
              builder: (_, cardC, __) {
                return ValueListenableBuilder<Color>(
                  valueListenable: AppTheme.glyphColor,
                  builder: (_, glyphC, __) {
                    return Card(
                      color: cardC.withValues(alpha: kCardBgOpacity),
                      clipBehavior: Clip.hardEdge,
                      child: InkWell(
                        onTap: () {
                          if (_isAraeA(glyph)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(UiText.t('araeOnly'))),
                            );
                            return;
                          }
                          try {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    WritingPracticePage(charGlyph: glyph),
                              ),
                            );
                          } catch (_) {}
                        },
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 위쪽: 글자 + 우상단 스피커
                              Expanded(
                                flex: 4,
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Text(
                                        glyph,
                                        style: TextStyle(
                                          fontSize: glyphFont,
                                          color:
                                          glyphC.withValues(alpha: .98),
                                          fontWeight: FontWeight.w800,
                                          height: 1.0,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: IconButton(
                                        tooltip: UiText.t('listen'),
                                        icon: const Icon(
                                          Icons.volume_up,
                                          size: 18,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints:
                                        const BoxConstraints.tightFor(
                                          width: 32,
                                          height: 32,
                                        ),
                                        onPressed: () =>
                                            AppTts.speakGlyphOrText(
                                              glyph,
                                              label: nameLabel,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              if (nameLabel.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  nameLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: nameFont,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: .96),
                                  ),
                                ),
                              ],

                              if (origin.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    origin,
                                    textAlign: TextAlign.center,
                                    softWrap: true,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                    theme.textTheme.bodySmall?.copyWith(
                                      fontSize: originFont,
                                      height: 1.25,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: .9),
                                    ),
                                  ),
                                ),
                              ],

                              if (!hasGuide)
                                const SizedBox(
                                  height: 0,
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
    );
  }
}
