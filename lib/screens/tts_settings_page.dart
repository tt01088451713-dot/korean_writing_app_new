// 예: lib/screens/tts_settings_page.dart
import 'package:flutter/material.dart';
import '../tts_helpers.dart';

class TtsSettingsPage extends StatefulWidget {
  const TtsSettingsPage({super.key});
  @override
  State<TtsSettingsPage> createState() => _TtsSettingsPageState();
}

class _TtsSettingsPageState extends State<TtsSettingsPage> {
  double rate = AppTts.rate;
  double pitch = AppTts.pitch;
  double volume = AppTts.volume;
  int queueMax = AppTts.queueMax;
  QueueOverflowPolicy policy = AppTts.overflowPolicy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TTS 설정')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _slider('속도', rate, 0.2, 1.0, (v) async {
            setState(() => rate = v);
            await AppTts.setSpeechRate(v);
          }),
          _slider('피치', pitch, 0.5, 2.0, (v) async {
            setState(() => pitch = v);
            await AppTts.setPitch(v);
          }),
          _slider('볼륨', volume, 0.0, 1.0, (v) async {
            setState(() => volume = v);
            await AppTts.setVolume(v);
          }),
          const SizedBox(height: 16),
          Row(children: [
            const Text('큐 최대 길이'),
            const SizedBox(width: 12),
            Expanded(
              child: Slider(
                min: 1,
                max: 64,
                divisions: 63,
                value: queueMax.toDouble(),
                label: '$queueMax',
                onChanged: (v) => setState(() => queueMax = v.toInt()),
                onChangeEnd: (v) => AppTts.setQueueMax(v.toInt()),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          DropdownButton<QueueOverflowPolicy>(
            value: policy,
            onChanged: (p) {
              if (p == null) return;
              setState(() => policy = p);
              AppTts.setQueueOverflowPolicy(p);
            },
            items: const [
              DropdownMenuItem(
                value: QueueOverflowPolicy.rejectNew,
                child: Text('큐 가득이면 새 항목 거절'),
              ),
              DropdownMenuItem(
                value: QueueOverflowPolicy.dropOldest,
                child: Text('큐 가득이면 가장 오래된 항목 삭제'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.volume_up),
            label: const Text('미리듣기'),
            onPressed: () => AppTts.speak('안녕하세요. 설정을 테스트합니다.'),
          ),
        ],
      ),
    );
  }

  Widget _slider(String label, double value, double min, double max,
      ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label  ${value.toStringAsFixed(2)}'),
        Slider(min: min, max: max, value: value, onChanged: onChanged),
        const SizedBox(height: 8),
      ],
    );
  }
}
