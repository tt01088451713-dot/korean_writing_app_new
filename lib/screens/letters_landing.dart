// lib/screens/letters_landing.dart
import 'package:flutter/material.dart';
import 'package:korean_writing_app_new/i18n/ui_texts.dart';
import 'package:korean_writing_app_new/screens/letters_category_page.dart';

/// Letters Landing
/// - 글자(문자 조합) 단원의 상위 랜딩 화면
/// - 각 세부 카테고리(2_1, 2_2, 2_3, 2_4)로 안전하게 이동
/// - 안정성 최우선: deprecated API 제거, mounted 체크, 예외 안전 처리
class LettersLandingPage extends StatelessWidget {
  const LettersLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final title = _safeText(UiText.t('lettersHubTitle')) ?? 'Letters';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: const [
            _CategoryCard(
              sectionId: '2_1',
              title: '좌우 결합형',
              subtitle: '기–히, 가–하, 갸–햐, 개–해, …',
              indexAssetPath: 'assets/data/letters/2_1/index.json',
            ),
            _CategoryCard(
              sectionId: '2_2',
              title: '상하 결합형',
              subtitle: '거–허, 겨–혀, 게–헤, 계–혯, …',
              indexAssetPath: 'assets/data/letters/2_2/index.json',
            ),
            _CategoryCard(
              sectionId: '2_3',
              title: 'ㅢ형(복합 모음형)',
              subtitle: '의 계열/복합 모음 조합',
              indexAssetPath: 'assets/data/letters/2_3/index.json',
            ),
            _CategoryCard(
              sectionId: '2_4',
              title: '받침 포함형(CV/CVC)',
              subtitle: '받침 포함 기초 조합',
              indexAssetPath: 'assets/data/letters/2_4/index.json',
            ),
          ],
        ),
      ),
    );
  }

  /// UiText.t()가 빈 문자열/누락일 수 있어 안전 처리
  String? _safeText(Object? v) {
    final s = (v ?? '').toString().trim();
    if (s.isEmpty) return null;
    return s;
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.sectionId,
    required this.title,
    required this.subtitle,
    required this.indexAssetPath,
  });

  final String sectionId;
  final String title;
  final String subtitle;
  final String indexAssetPath;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openCategory(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              _Badge(text: sectionId),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 부제(설명)
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCategory(BuildContext context) async {
    // 예외 안전 네비게이션
    try {
      // 동기 push이므로 use_build_context_synchronously 경고 없음
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LettersCategoryPage(
            title: title,
            indexAssetPath: indexAssetPath, // ✅ 에러 해결: 존재하는 파라미터
            sectionId: sectionId,
          ),
        ),
      );
    } catch (_) {
      // 사용자에게 과도한 노출 없이 조용히 무시 (릴리스 안정성 우선)
      // 필요하다면 ScaffoldMessenger로 짧은 안내 토스트 가능
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('열기 실패: $sectionId'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08), // withOpacity 대체
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.primary.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: cs.primary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
