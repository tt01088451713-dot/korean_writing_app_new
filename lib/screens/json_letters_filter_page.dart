// lib/screens/json_letters_filter_page.dart
import 'package:flutter/material.dart';

/// 초성(또는 문자열 태그) 필터 선택 화면.
/// - [initials]: 표시할 후보 목록
/// - [preselected]: 미리 선택된 값
/// 완료 시 Navigator.pop(context, Set<String>) 으로 선택 결과를 반환합니다.
class JsonLettersFilterPage extends StatefulWidget {
  const JsonLettersFilterPage({
    super.key,
    this.initials = const [],
    this.preselected = const {},
    this.title,
  });

  /// 표시할 후보. 비어 있으면 기본 초성 배열을 사용.
  final List<String> initials;

  /// 미리 선택된 값.
  final Set<String> preselected;

  /// 앱바 타이틀(옵션)
  final String? title;

  @override
  State<JsonLettersFilterPage> createState() => _JsonLettersFilterPageState();
}

class _JsonLettersFilterPageState extends State<JsonLettersFilterPage> {
  late final List<String> _candidates;
  late final Set<String> _selected;

  static const List<String> _defaultInitials = <String>[
    'ㄱ',
    'ㄲ',
    'ㄴ',
    'ㄷ',
    'ㄸ',
    'ㄹ',
    'ㅁ',
    'ㅂ',
    'ㅃ',
    'ㅅ',
    'ㅆ',
    'ㅇ',
    'ㅈ',
    'ㅉ',
    'ㅊ',
    'ㅋ',
    'ㅌ',
    'ㅍ',
    'ㅎ'
  ];

  @override
  void initState() {
    super.initState();
    _candidates = (widget.initials.isEmpty ? _defaultInitials : widget.initials)
        .toList()
      ..sort(_koreanInitialSort);
    _selected = {...widget.preselected};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? '초성 선택'),
        actions: [
          TextButton(
            onPressed: () => setState(_selectAll),
            child: const Text('전체', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => setState(_clearAll),
            child: const Text('해제', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: _candidates.isEmpty
            ? const Center(child: Text('표시할 항목이 없습니다.'))
            : SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final ini in _candidates)
                      FilterChip(
                        label: Text(ini),
                        selected: _selected.contains(ini),
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              _selected.add(ini);
                            } else {
                              _selected.remove(ini);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context), // 취소(반환 없음)
                  child: const Text('취소'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      Navigator.pop<Set<String>>(context, _selected),
                  icon: const Icon(Icons.check),
                  label: const Text('적용'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectAll() => _selected
    ..clear()
    ..addAll(_candidates);

  void _clearAll() => _selected.clear();

  // 한글 초성 정렬(프로젝트의 다른 페이지와 일관성 유지)
  int _koreanInitialSort(String a, String b) {
    const order = 'ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ';
    final ai = order.indexOf(a);
    final bi = order.indexOf(b);
    if (ai == -1 && bi == -1) return a.compareTo(b);
    if (ai == -1) return 1;
    if (bi == -1) return -1;
    return ai.compareTo(bi);
  }
}
