// lib/screens/unit_1_1_consonantal_letter.dart
import 'package:flutter/material.dart';

// 데이터 로더 / TTS / 쓰기 연습
import 'package:korean_writing_app_new/data_loader/data_loader.dart';
import 'package:korean_writing_app_new/tts_helpers.dart';
import 'package:korean_writing_app_new/screens/writing_practice_page.dart';

// i18n
import 'package:korean_writing_app_new/i18n/language_state.dart';
import 'package:korean_writing_app_new/i18n/i18n_utils.dart';
import 'package:korean_writing_app_new/i18n/ui_texts.dart';

// 테마
import 'package:korean_writing_app_new/theme_state.dart';

/// 자음자 데이터 경로
const String kUnitAsset = 'assets/data/1_1_consonantal_letter.json';

/// Map 형태로 들어온 {ko:, en:, ...} 에서 현재 언어 우선으로 값을 고르는 헬퍼
String _pickI18nFromMap(Map m) {
  final code = LanguageState.I.code.toLowerCase();
  final base = code.split('-').first;
  final cands = <String>[code, base, 'en', 'ko'];
  for (final k in cands) {
    final v = m[k];
    if (v is String && v.trim().isNotEmpty) return v;
  }
  // 첫 값 폴백
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

class UnitOverviewPage extends StatefulWidget {
  const UnitOverviewPage({super.key});
  @override
  State<UnitOverviewPage> createState() => _UnitOverviewPageState();
}

class _UnitOverviewPageState extends State<UnitOverviewPage> {
  late Future<Map<String, dynamic>> future;

  // 반응형 스케일(가독성 향상을 위해 살짝 보수적)
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
            appBar: AppBar(title: Text(UiText.t('menuConsonants'))),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText('Error:\n${snap.error}'),
            ),
          );
        }

        final data = snap.data!;
        final jsonTitle = pickI18n(data, 'title');
        final subtitle = pickI18n(data, 'subtitle');

        // AppBar 제목(우선순위: JSON title > i18n 기본키)
        final appBarTitle =
        (jsonTitle.isNotEmpty ? jsonTitle : UiText.t('menuConsonants'))
            .trim();

        // 개요(overview_* 또는 overview(Map) 또는 introduction_ko 폴백)
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

        // 본문 상단 제목을 AppBar와 “중복이면 숨김”
        final bodyTitle = jsonTitle.trim();
        final bool showBodyTitle =
            bodyTitle.isNotEmpty && bodyTitle != appBarTitle;

        return Scaffold(
          appBar: AppBar(
            title: Text(appBarTitle),
            actions: [
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'lang') {
                    Navigator.pushReplacementNamed(context, '/'); // 언어 선택
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
                if (showBodyTitle) Text(bodyTitle, style: titleStyle),
                if (subtitle.isNotEmpty) ...[
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

  int _calcCols(double w) {
    if (w >= 1200) return 8;
    if (w >= 1024) return 7;
    if (w >= 900) return 6;
    if (w >= 700) return 5;
    if (w >= 520) return 4;
    // 🔧 스마트폰(좁은 화면)에서는 2칸으로 줄여 세로 공간 확보
    return 2;
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
    // 글자 폰트를 살짝 줄여 여백 확보
    final glyphFont = (28 * scale).clamp(24, 34).toDouble();
    final nameFont = (14 * scale).clamp(13, 16).toDouble();
    final originFont = (12.5 * scale).clamp(12, 14.5).toDouble();

    // 카드 하나 만드는 빌더
    Widget buildCard(dynamic it) {
      String glyph = '';
      String nameLabel = '';
      String origin = '';

      if (it is Map) {
        glyph = (it['char'] ?? it['glyph'] ?? it['text'] ?? '').toString();

        // 이름: name_* 또는 name(Map) 지원
        nameLabel = pickI18n(it, 'name');
        if (nameLabel.isEmpty) {
          final rawName = it['name'];
          if (rawName is Map) nameLabel = _pickI18nFromMap(rawName);
        }

        origin = _pickOrigin(it); // 다국어 우선
        if (glyph.isEmpty) {
          glyph = '${it['glyph'] ?? it['char'] ?? it['text'] ?? it}';
        }
      } else {
        glyph = '$it';
      }

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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            WritingPracticePage(charGlyph: glyph),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
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
                                    color: glyphC.withValues(alpha: .98),
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
                                    size: 18, // 살짝 줄여 덜 붙어 보이게
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints.tightFor(
                                    width: 32,
                                    height: 32,
                                  ),
                                  onPressed: () => AppTts.speakGlyphOrText(
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
                              maxLines: 3, // 3줄까지 표시
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: originFont,
                                height: 1.25,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: .9),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    }

    // items → Map 보정
    final data =
    items.map((e) => e is Map ? e : {'glyph': '$e'}).cast<Map>().toList();

    // 그룹핑 함수 (기존 로직 유지)
    String groupOf(Map it) {
      final glyph = (it['char'] ?? it['glyph'] ?? '').toString();
      final id = (it['id'] ?? '').toString().toLowerCase();

      const basicGlyphs = ['ㄱ', 'ㄴ', 'ㅁ', 'ㅅ', 'ㅇ'];
      const strokedGlyphs = ['ㅋ', 'ㄷ', 'ㅌ', 'ㅂ', 'ㅍ', 'ㅈ', 'ㅊ', 'ㅎ'];
      if (basicGlyphs.contains(glyph)) return 'basic';
      if (strokedGlyphs.contains(glyph)) return 'stroked';
      if (glyph == 'ㄹ') return 'variant';

      const basicIds = {
        'giyeok',
        'kiyeok',
        'giyok',
        'kiyok',
        'nieun',
        'mieum',
        'mi-eum',
        'siot',
        'shiot',
        'si-ot',
        'ieung',
        'yiung',
      };
      const strokedIds = {
        'kieuk',
        'kieok',
        'kiek',
        'ki-euk',
        'digeut',
        'digeud',
        'di-geut',
        'tieut',
        'ti-eut',
        'bieup',
        'bi-eup',
        'pieup',
        'pi-eup',
        'jieut',
        'ji-eut',
        'chieut',
        'chi-eut',
        'hieut',
        'hi-eut',
      };
      if (basicIds.contains(id)) return 'basic';
      if (strokedIds.contains(id)) return 'stroked';
      if (id == 'rieul' || id == 'li-eul' || id == 'rieul-variant') {
        return 'variant';
      }

      return 'basic';
    }

    final grouped = <String, List<Map>>{
      'basic': [],
      'stroked': [],
      'variant': [],
    };
    for (final it in data) {
      grouped[groupOf(it)]!.add(it);
    }

    final order = ['basic', 'stroked', 'variant']
        .where((k) => grouped[k]!.isNotEmpty)
        .toList();

    String label(String g) {
      switch (g) {
        case 'basic':
          return UiText.t('basicCons');
        case 'stroked':
          return UiText.t('extendedCons');
        case 'variant':
          return UiText.t('variantCons');
        default:
          return UiText.t('others');
      }
    }

    return LayoutBuilder(
      builder: (context, c) {
        final cols = _calcCols(c.maxWidth);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final g in order) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
                child: Text(
                  label(g),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: (16 * scale).clamp(15, 18).toDouble(),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 4),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio:
                  0.85, // 세로 공간을 조금 더 확보
                ),
                itemCount: grouped[g]!.length,
                itemBuilder: (_, i) => buildCard(grouped[g]![i]),
              ),
              const SizedBox(height: 4),
            ],
          ],
        );
      },
    );
  }
}
