// lib/screens/language_gate.dart
import 'package:flutter/material.dart';
import 'package:korean_writing_app_new/lang_state.dart';
import 'package:korean_writing_app_new/i18n/ui_texts.dart';

String _t(String key, String defaults) {
  try {
    final s = UiText.t(key);
    if (s is String && s.trim().isNotEmpty) return s;
  } catch (_) {}
  return defaults;
}

class LanguageGatePage extends StatelessWidget {
  const LanguageGatePage({super.key});

  void _selectLanguage(BuildContext context, String code) {
    try {
      // 구현에 따라 set이 있을 수도/없을 수도 있어요.
      // 있으면 그걸 쓰고, 없으면 value에 대입해도 됩니다.
      // AppLang.set(code);
      // ↑ set 메서드가 없다면 주석 유지
      // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
      AppLang.value = code;
    } catch (_) {}

    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    Map<String, String> langs = const {'ko': '한국어 (Korean)', 'en': 'English'};
    try {
      final any = UiText.supportedLangs;
      if (any is Map && any.isNotEmpty) {
        langs = any.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    } catch (_) {}

    return Scaffold(
      appBar: AppBar(title: Text(_t('selectLanguage', '언어 선택'))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    _t('selectLanguagePrompt', '앱에서 사용할 언어를 선택하세요.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.separated(
                      itemCount: langs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final code = langs.keys.elementAt(i);
                        final name = langs[code]!;
                        final isCurrent = (() {
                          try {
                            // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
                            return AppLang.value == code;
                          } catch (_) {
                            return false;
                          }
                        })();
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.outlineVariant,
                            ),
                          ),
                          leading: const Icon(Icons.language),
                          title: Text(name),
                          trailing: isCurrent
                              ? Icon(Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary)
                              : null,
                          onTap: () => _selectLanguage(context, code),
                        );
                      },
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

// 예전 코드 호환용 별칭
class LanguageGate extends StatelessWidget {
  const LanguageGate({super.key});
  @override
  Widget build(BuildContext context) => const LanguageGatePage();
}
