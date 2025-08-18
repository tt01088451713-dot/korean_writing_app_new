import 'package:flutter/material.dart';
import 'package:korean_writing_app_new/i18n/ui_texts.dart';

class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Text(
          UiText.t('comingSoon'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
