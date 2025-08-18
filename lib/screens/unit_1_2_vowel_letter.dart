import 'package:flutter/material.dart';

import 'package:korean_writing_app_new/data_loader/data_loader.dart';
import 'package:korean_writing_app_new/tts_helpers.dart';
import 'package:korean_writing_app_new/lang_state.dart';
import 'package:korean_writing_app_new/screens/writing_practice_page.dart';

import 'package:korean_writing_app_new/i18n/ui_texts.dart';
import 'package:korean_writing_app_new/theme_state.dart';

/// 모음자 데이터 경로
const String kVowelAsset = 'assets/data/1_2_vowel_letter.json';

/// 다국어 필드에서 언어 우선 선택 (기본: AppLang.value)
String pickMl(dynamic v, {String? lang}) {
  final use = lang ?? AppLang.value;
  if (v == null) return '';
  if (v is String) return v;
  if (v is Map) {
    final val = v[use] ?? (v['ko'] ?? (v.values.isNotEmpty ? v.values.first : ''));
    return '$val';
  }
  return '$v';
}

/// 설명 추출: description(다국어) → description_ko
String pickDesc(Map p) {
  final dMl = pickMl(p['description']);
  if (dMl.isNotEmpty) return dMl;
  final dKo = p['description_ko'];
  if (dKo is String && dKo.isNotEmpty) return dKo;
  return '';
}

/// 파트 제목: title(다국어) → groupKey를 UiText로 → part(ko 문자열)
String partTitleOf(Map p) {
  final t = pickMl(p['title']);
  if (t.isNotEmpty) return t;

  final gk = p['groupKey'];
  if (gk is String && gk.isNotEmpty) {
    final label = UiText.t(gk);
    if (label.isNotEmpty && label != gk) return label;
  }

  final s = p['part'];
  if (s is String && s.isNotEmpty) return s;
  return 'Section';
}

/// 카드 하단 설명: origin(다국어) → origin_ko → principle → principle_translation
String pickOrigin(Map item) {
  final oMl = pickMl(item['origin']);
  if (oMl.isNotEmpty) return oMl;

  final oKo = item['origin_ko'];
  if (oKo is String && oKo.isNotEmpty) return oKo;

  final pr = item['principle'];
  if (pr is String && pr.isNotEmpty) return pr;

  final prTr = item['principle_translation']; // {ko:..., en:...}
  if (prTr is Map) {
    final byLang = prTr[AppLang.value];
    if (byLang is String && byLang.isNotEmpty) return byLang;
    if (prTr.values.isNotEmpty) return '${prTr.values.first}';
  }
  return '';
}

class UnitVowelPage extends StatefulWidget {
  const UnitVowelPage({super.key});
  @override
  State<UnitVowelPage> createState() => _UnitVowelPageState();
}

class _UnitVowelPageState extends State<UnitVowelPage> {
  late Future<Map<String, dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = loadJsonAsset(kVowelAsset);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, s) {
        if (s.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (s.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text(UiText.t('menuVowels'))),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText('Error:\n${s.error}'),
            ),
          );
        }

        final data = s.data!;
        final title = pickMl(data['title']);
        final subtitle = pickMl(data['subtitle']);

        // 개요: i18n 우선 → ko 소개 폴백
        String overview = pickMl(data['overview']);
        if (overview.isEmpty) {
          final koIntro = data['introduction_ko'];
          if (koIntro is String) overview = koIntro;
        }

        final parts = (data['parts'] as List?) ?? const [];

        return Scaffold(
          appBar: AppBar(
            title: Text(title.isNotEmpty ? title : UiText.t('menuVowels')),
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
                  PopupMenuItem(value: 'lang', child: Text(UiText.t('changeLanguage'))),
                  PopupMenuItem(value: 'theme', child: Text(UiText.t('customizeColors'))),
                ],
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                if (subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('($subtitle)', style: Theme.of(context).textTheme.titleMedium),
                  ),
                if (overview.isNotEmpty) ...[
                  Text(overview),
                  const SizedBox(height: 14),
                ],
                if (parts.isEmpty)
                  const Text('목록이 비어 있습니다. (parts[*].chars 경로를 확인하세요)'),

                ...parts.map((pAny) {
                  final p = pAny as Map;
                  final partTitle = partTitleOf(p);
                  final partDesc = pickDesc(p);
                  final chars = (p['chars'] as List?) ?? const [];
                  final subparts = (p['subparts'] as List?) ?? const [];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        partTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (partDesc.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(partDesc, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                      const SizedBox(height: 8),

                      // subparts가 없으면 이 파트의 chars를 섹션으로 분류하여 출력
                      if (subparts.isEmpty && chars.isNotEmpty) _VowelGrid(chars),

                      // 서브 파트가 있으면 각자 출력
                      ...subparts.map((spAny) {
                        final sp = spAny as Map;
                        final subTitle = partTitleOf(sp);
                        final subDesc = pickDesc(sp);
                        final subChars = (sp['chars'] as List?) ?? const [];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            Text(
                              subTitle,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (subDesc.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(subDesc, style: Theme.of(context).textTheme.bodySmall),
                            ],
                            const SizedBox(height: 6),
                            _VowelGrid(subChars),
                          ],
                        );
                      }),
                      const SizedBox(height: 8),
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

  // 색상 설정 시트
  void _showColorSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(UiText.t('customizeColors'), style: const TextStyle(fontWeight: FontWeight.bold)),
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

/// ─────────────────────────────────────────────────────────────
/// 그리드 + 분류(기본/초출/재출/이자합용/ㅣ상합)
/// ─────────────────────────────────────────────────────────────
class _VowelGrid extends StatelessWidget {
  const _VowelGrid(this.items, {super.key});
  final List items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Text('항목이 없습니다.'),
      );
    }

    // 카드(공통 UI) 빌더
    Widget buildCard(dynamic it) {
      String glyph = '';
      String nameLabel = '';
      String origin = '';

      if (it is Map) {
        glyph = (it['char'] ?? it['glyph'] ?? it['text'] ?? '').toString();
        nameLabel = pickMl(it['name']);
        if (nameLabel.isEmpty) nameLabel = (it['name_ko'] ?? '').toString();
        origin = pickOrigin(it);
        if (glyph.isEmpty) glyph = pickMl(it);
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
                color: cardC.withOpacity(kCardBgOpacity),
                clipBehavior: Clip.hardEdge,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WritingPracticePage(charGlyph: glyph),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(glyph, style: TextStyle(fontSize: 28, color: glyphC)),
                              if (nameLabel.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    nameLabel,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              if (origin.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    origin,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      height: 1.25,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: IconButton(
                            tooltip: UiText.t('read'),
                            icon: const Icon(Icons.volume_up, size: 18),
                            onPressed: () => AppTts.speakGlyphOrText(glyph, label: nameLabel),
                          ),
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
    }

    // ── 분류 로직 ─────────────────────────────────────────
    // 데이터에 group/groupKey 있으면 우선 사용 → 없으면 glyph/id로 추론
    String inferGroup(Map it) {
      final explicit = (it['group'] ?? it['groupKey'])?.toString();
      if (explicit != null && explicit.isNotEmpty) {
        final m = {
          'basicVowels': 'basic',
          'firstDerivedVowels': 'first',
          'secondDerivedVowels': 'second',
          'mixedCompoundVowels': 'mixed',
          'iHarmonyVowels': 'ih',
          // 혹시 'basic','first','second','mixed','ih'로 들어온 경우
          'basic': 'basic',
          'first': 'first',
          'second': 'second',
          'mixed': 'mixed',
          'ih': 'ih',
        };
        if (m.containsKey(explicit)) return m[explicit]!;
      }

      final glyph = (it['char'] ?? it['glyph'] ?? '').toString();
      final id = (it['id'] ?? '').toString().toLowerCase();

      // 1) 글자 기준 (최우선)
      const basicGlyphs = ['ㆍ', 'ㅡ', 'ㅣ'];
      const firstGlyphs = ['ㅏ', 'ㅓ', 'ㅗ', 'ㅜ'];
      const secondGlyphs = ['ㅑ', 'ㅕ', 'ㅛ', 'ㅠ'];
      const mixedGlyphs = ['ㅘ', 'ㅝ', 'ㅙ', 'ㅞ']; // 혼합 합용
      const iHarmonyGlyphs = ['ㅐ', 'ㅔ', 'ㅚ', 'ㅟ', 'ㅢ', 'ㅖ', 'ㅒ']; // ㅣ상합

      if (basicGlyphs.contains(glyph)) return 'basic';
      if (firstGlyphs.contains(glyph)) return 'first';
      if (secondGlyphs.contains(glyph)) return 'second';
      if (mixedGlyphs.contains(glyph)) return 'mixed';
      if (iHarmonyGlyphs.contains(glyph)) return 'ih';

      // 2) id(별칭 포함) 보조 판단
      const basicIds = {'arae_a','eu','i','ㅡ','ㅣ','ㆍ'};
      const firstIds = {'a','eo','o','u'};
      const secondIds = {'ya','yeo','yo','yu'};
      const mixedIds = {'wa','wo','wae','we'};
      const ihIds = {'ae','e','oe','wi','ui','ye','yae'};

      if (basicIds.contains(id)) return 'basic';
      if (firstIds.contains(id)) return 'first';
      if (secondIds.contains(id)) return 'second';
      if (mixedIds.contains(id)) return 'mixed';
      if (ihIds.contains(id)) return 'ih';

      return 'basic';
    }

    // Map 변환
    final data = items.map((e) => e is Map ? e : {'glyph': '$e'}).cast<Map>().toList();

    // 그룹핑
    final grouped = <String, List<Map>>{
      'basic': [],
      'first': [],
      'second': [],
      'mixed': [],
      'ih': [],
    };
    for (final it in data) {
      grouped[inferGroup(it)]!.add(it);
    }

    // 실제 섹션만 출력
    final order = ['basic', 'first', 'second', 'mixed', 'ih']
        .where((k) => grouped[k]!.isNotEmpty)
        .toList();

    String label(String g) {
      switch (g) {
        case 'basic': return UiText.t('basicVowels');
        case 'first': return UiText.t('firstDerivedVowels');
        case 'second': return UiText.t('secondDerivedVowels');
        case 'mixed': return UiText.t('mixedCompoundVowels');
        case 'ih': return UiText.t('iHarmonyVowels');
        default: return UiText.t('others');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final g in order) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
            child: Text(
              label(g),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.18,
            ),
            itemCount: grouped[g]!.length,
            itemBuilder: (_, i) => buildCard(grouped[g]![i]),
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}
