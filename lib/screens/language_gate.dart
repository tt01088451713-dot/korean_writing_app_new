// lib/screens/language_gate.dart
import 'package:flutter/material.dart';
import 'package:korean_writing_app_new/i18n/language_state.dart';
import 'package:korean_writing_app_new/i18n/ui_texts.dart';

/// ---------- 안전 유틸 ----------
String _t(String key, String fallback) {
  try {
    final s = UiText.t(key);
    if (s.trim().isNotEmpty && s != key) return s;
  } catch (_) {}
  return fallback;
}

String _currentLang() {
  try {
    final v = LanguageState.I.code;
    if (v.isNotEmpty) return v.toLowerCase();
  } catch (_) {}
  return 'ko';
}

Future<void> _applyLanguage(String code) async {
  try {
    await LanguageState.I.set(code);
  } catch (_) {}

  // 커스텀 로케일 핸들러 대비(없어도 무해)
  try {
    // ignore: invalid_use_of_protected_member
    (UiText as dynamic).setLocale?.call(code);
  } catch (_) {
    try {
      // ignore: invalid_use_of_protected_member
      (UiText as dynamic).setLang?.call(code);
    } catch (_) {}
  }
}

/// ---------- 화면 ----------
class LanguageGatePage extends StatelessWidget {
  const LanguageGatePage({super.key});

  Future<void> _onSelect(
    BuildContext context, {
    required String code,
    required String visibleLabel,
  }) async {
    try {
      await _applyLanguage(code);
      if (context.mounted) {
        final appliedText = _t('langApplied', '언어가 적용되었습니다: ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$appliedText$visibleLabel')),
        );
      }
    } catch (e) {
      debugPrint('Language select error: $e');
    }

    if (!context.mounted) return;

    // 홈으로 이동(라우트 유무에 따른 폴백 포함)
    try {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
    } catch (_) {
      try {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1) 지원 언어(순서 유지: 안정성)
    final supported = LanguageState.supported;

    // 2) UiText 라벨 테이블(있으면 사용, 순서 변경 금지)
    Map<String, String> uiTextLabels = const {};
    try {
      final any = UiText.supportedLangs;
      if (any.isNotEmpty) {
        final m = <String, String>{};
        any.forEach((k, v) {
          final kk = k.toString().trim().toLowerCase();
          final vv = v.toString().trim();
          if (kk.isNotEmpty && vv.isNotEmpty) m[kk] = vv;
        });
        uiTextLabels = m;
      }
    } catch (_) {}

    // 현재 언어(지역코드 가능)
    final current = _currentLang();

    // ---------- 텍스트 선명도/가독성 ----------
    const headingStyle = TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      height: 1.25,
    );

    const tileTitleStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      height: 1.18,
      letterSpacing: 0.1,
      color: Colors.black87,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('selectLanguage', '언어를 선택하세요')),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    _t('selectLanguagePrompt', '앱에서 사용할 언어를 고르세요.'),
                    textAlign: TextAlign.center,
                    style: headingStyle,
                  ),
                  const SizedBox(height: 20),

                  // 언어 리스트
                  Expanded(
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: ListView.separated(
                        itemCount: supported.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final li = supported[i];

                          // 방어적 접근: 구조가 달라도 크래시 방지
                          final code = (() {
                            try {
                              final v = (li as dynamic).code?.toString();
                              return (v ?? '').toLowerCase();
                            } catch (_) {
                              return '';
                            }
                          })();
                          if (code.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          // 라벨 우선순위: UiText 라벨 > LanguageInfo.label > native > code
                          final name = (() {
                            final ui = uiTextLabels[code];
                            if (ui != null && ui.trim().isNotEmpty) return ui;
                            try {
                              final lbl =
                                  (li as dynamic).label?.toString() ?? '';
                              if (lbl.trim().isNotEmpty) return lbl;
                            } catch (_) {}
                            try {
                              final nat =
                                  (li as dynamic).native?.toString() ?? '';
                              if (nat.trim().isNotEmpty) return nat;
                            } catch (_) {}
                            return code;
                          })();

                          final isCurrent =
                              current == code || current.startsWith('$code-');

                          return Semantics(
                            selected: isCurrent,
                            button: true,
                            label: 'Language $name',
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8, // 터치 영역 확대
                              ),
                              leading: const Icon(Icons.language,
                                  color: Colors.black87),
                              title: Text(name, style: tileTitleStyle),
                              trailing: isCurrent
                                  ? Icon(
                                      Icons.check_circle,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    )
                                  : null,
                              onTap: () => _onSelect(
                                context,
                                code: code,
                                visibleLabel: name,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Text(
                    _t('youCanChangeLanguageLater',
                        '설정에서 언제든지 언어를 변경할 수 있습니다.'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 레거시 라우트 호환용
class LanguageGate extends StatelessWidget {
  const LanguageGate({super.key});
  @override
  Widget build(BuildContext context) => const LanguageGatePage();
}
