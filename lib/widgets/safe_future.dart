// lib/widgets/safe_future.dart
import 'dart:async';
import 'package:flutter/material.dart';

class SafeFuture<T> extends StatelessWidget {
  const SafeFuture({
    super.key,
    required this.future,
    required this.builder,
    this.timeout = const Duration(seconds: 8),
    this.label = '로딩',
  });

  final Future<T> future;
  final Widget Function(BuildContext, T) builder;
  final Duration timeout;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future.timeout(timeout, onTimeout: () {
        throw TimeoutException('[$label] 응답 지연(>${timeout.inSeconds}s)');
      }),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: Text('준비 중입니다…'));
        }
        if (snap.hasError) {
          return _ErrorView(error: snap.error, stack: snap.stackTrace);
        }
        if (!snap.hasData) {
          return const _ErrorView(error: '데이터 없음(null)');
        }
        return builder(context, snap.data as T);
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({this.error, this.stack});
  final Object? error;
  final StackTrace? stack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: SelectableText(
              '❌ 로딩 실패\n\n$error\n\n${stack ?? ''}',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}
