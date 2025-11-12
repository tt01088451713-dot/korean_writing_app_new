import 'package:flutter/material.dart';
import '../utils/frequency_filter.dart';

class JsonTagsOnlyPage extends StatefulWidget {
  const JsonTagsOnlyPage({super.key});
  @override
  State<JsonTagsOnlyPage> createState() => _JsonTagsOnlyPageState();
}

class _JsonTagsOnlyPageState extends State<JsonTagsOnlyPage> {
  FrequencyFilter? ff;
  final List<String> demo = ["원", "월", "웬", "윙", "괼(괴)", "웝", "윌"];

  @override
  void initState() {
    super.initState();
    FrequencyFilter.load().then((f) => setState(() => ff = f));
  }

  @override
  Widget build(BuildContext context) {
    if (ff == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final filtered = ff!.apply(demo);
    return Scaffold(
      appBar: AppBar(title: const Text('Tags Only Test')),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('희귀 항목 숨기기'),
            value: ff!.hideRare,
            onChanged: (v) => setState(() => ff!.hideRare = v),
          ),
          const Divider(height: 1),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filtered.map((s) => Chip(label: Text(s))).toList(),
          ),
        ],
      ),
    );
  }
}
