import 'package:flutter/material.dart';

// 패키지 경로 임포트
import 'package:korean_writing_app_new/data_loader/data_loader.dart';
import 'package:korean_writing_app_new/tts_helpers.dart';
import 'package:korean_writing_app_new/lang_state.dart';
import 'package:korean_writing_app_new/screens/writing_practice_page.dart';

// i18n/테마
import 'package:korean_writing_app_new/i18n/ui_texts.dart';
import 'package:korean_writing_app_new/theme_state.dart';
import 'package:korean_writing_app_new/data_loader/stroke_assets.dart';

/// 모음자 데이터 경로
const String kUnitAsset = 'assets/data/1_2_vowel_letter.json';

/// 다국어 필드에서 현재 언어 텍스트 선택
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

/// 파트/서브파트 설명: description(맵) 우선 → description_ko 폴백
String pickDesc(Map p) {
  final dMl = pickMl(p['description']);
  if (dMl.isNotEmpty) return dMl;
  final dKo = p['description_ko'];
  if (dKo is String && dKo.isNotEmpty) return dKo;
  return '';
}

/// 파트 제목: title(맵) 우선 → groupKey를 UiText로 → part(ko 문자열) 폴백
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

/// 카드 하단 설명: origin(맵) 우선 → origin_ko → principle → principle_translation
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

class VowelOverviewPage extends StatefulWidget {
  const VowelOverviewPage({super.key});
  @override
  State<VowelOverviewPage> createState() => _VowelOverviewPageState();
}

class _VowelOverviewPageState extends State<VowelOverviewPage> {
  late Future<Map<String, dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = loadJsonAsset(kUnitAsset);
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

        String overview = pickMl(data['overview']);
        if (overview.isEmpty) {
          final koIntro = data['introduction_ko'];
          if (koIntro is String) overview = koIntro;
        }

        final parts = (data['parts'] as List?) ?? [];

        return Scaffold(
          appBar: AppBar(
            title: Text(title.isNotEmpty ? title : UiText.t('menuVowels')),
            actions: [
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'lang') {
                    Navigator.pushReplacementNamed(context, '/');
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

                      if (subparts.isEmpty && chars.isNotEmpty) _GlyphGrid(chars),

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
                            _GlyphGrid(subChars),
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

class _GlyphGrid extends StatelessWidget {
  const _GlyphGrid(this.items, {super.key});
  final List items;

  bool _isAraeA(String glyph) => glyph == 'ㆍ';

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Text('항목이 없습니다.'),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.18,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final it = items[i];

        String glyph = '';
        String nameLabel = '';
        String origin = '';

        if (it is Map) {
          glyph = (it['char'] ?? it['glyph'] ?? it['text'] ?? '').toString();
          nameLabel = pickMl(it['name']);
          if (nameLabel.isEmpty) {
            nameLabel = (it['name_ko'] ?? '').toString();
          }
          origin = pickOrigin(it);
          if (glyph.isEmpty) glyph = pickMl(it);
        } else {
          glyph = '$it';
        }

        // 가이드 자산 존재 여부만 확인(안내 문구는 모음 화면에서 표시하지 않음)
        final guide = StrokeAssets.get(glyph);
        final hasGuide = guide != null;

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
                      if (_isAraeA(glyph)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(UiText.t('araeOnly'))),
                        );
                        return;
                      }
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
                                // (모음 화면은 compositeNote를 표시하지 않습니다)
                                if (!hasGuide) const SizedBox(height: 0),
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
      },
    );
  }
}
