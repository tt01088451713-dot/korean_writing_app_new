// lib/screens/writing_practice_page.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart'; // ← 단축키
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:korean_writing_app_new/data_loader/stroke_assets.dart';
import 'package:korean_writing_app_new/i18n/ui_texts.dart';
import 'package:korean_writing_app_new/tts_helpers.dart';

// ───────── 저장 키 ─────────
const _kShowGuide = 'draw.showGuide';
const _kShowGrid  = 'draw.showGrid';
const _kWidth     = 'draw.strokeWidth';

class WritingPracticePage extends StatefulWidget {
  const WritingPracticePage({super.key, required this.charGlyph});
  final String charGlyph;

  @override
  State<WritingPracticePage> createState() => _WritingPracticePageState();
}

class _WritingPracticePageState extends State<WritingPracticePage> {
  // drawing state
  final _paths = <Path>[];
  final _paints = <Paint>[];
  Path? _current;

  // UI toggles
  bool _showGuide = true;
  bool _showGrid = true;
  double _strokeWidth = 6;
  Color _strokeColor = Colors.blueGrey;

  // for saving
  final _captureKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _showGuide   = p.getBool(_kShowGuide) ?? true;
      _showGrid    = p.getBool(_kShowGrid)  ?? true;
      _strokeWidth = p.getDouble(_kWidth)   ?? 6;
    });
  }

  Future<void> _savePrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kShowGuide, _showGuide);
    await p.setBool(_kShowGrid,  _showGrid);
    await p.setDouble(_kWidth,   _strokeWidth);
  }

  // ───────── 단축키용 Intent ─────────
  static const _undoIntent = _UndoIntent();
  static const _saveIntent = _SaveIntent();
  static const _toggleGridIntent  = _ToggleGridIntent();
  static const _toggleGuideIntent = _ToggleGuideIntent();

  @override
  Widget build(BuildContext context) {
    final glyph = widget.charGlyph;

    // ✅ 변경 포인트: 실제 가이드 자산 존재 여부로 연습 가능/불가 결정
    final guide = StrokeAssets.get(glyph);
    // guide가 없으면 가이드 전용(그리기 불가), 있으면 연습 허용
    final guideOnly = (guide == null);

    final shortcuts = <LogicalKeySet, Intent>{
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ): _undoIntent,
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): _saveIntent,
      LogicalKeySet(LogicalKeyboardKey.keyG): _toggleGridIntent,
      LogicalKeySet(LogicalKeyboardKey.keyH): _toggleGuideIntent,
    };

    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          _UndoIntent: CallbackAction<_UndoIntent>(onInvoke: (_) {
            if (!guideOnly && _paths.isNotEmpty) {
              setState(() { _paths.removeLast(); _paints.removeLast(); });
            }
            return null;
          }),
          _SaveIntent: CallbackAction<_SaveIntent>(onInvoke: (_) {
            _saveAsPng(context, glyph);
            return null;
          }),
          _ToggleGridIntent: CallbackAction<_ToggleGridIntent>(onInvoke: (_) {
            setState(() => _showGrid = !_showGrid);
            _savePrefs();
            return null;
          }),
          _ToggleGuideIntent: CallbackAction<_ToggleGuideIntent>(onInvoke: (_) {
            setState(() => _showGuide = !_showGuide);
            _savePrefs();
            return null;
          }),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              title: Text('$glyph ${UiText.t("practice")}'),
              actions: [
                IconButton(
                  tooltip: UiText.t('read'),
                  icon: const Icon(Icons.volume_up),
                  onPressed: () => AppTts.speakGlyphOrText(glyph),
                ),
                IconButton(
                  tooltip: UiText.t('toggleGuide'),
                  icon: Icon(_showGuide ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() => _showGuide = !_showGuide);
                    _savePrefs();
                  },
                ),
                IconButton(
                  tooltip: UiText.t('toggleGrid'),
                  icon: const Icon(Icons.grid_on),
                  onPressed: () {
                    setState(() => _showGrid = !_showGrid);
                    _savePrefs();
                  },
                ),
                if (!guideOnly) ...[
                  IconButton(
                    tooltip: UiText.t('undo'),
                    icon: const Icon(Icons.undo),
                    onPressed: () {
                      if (_paths.isNotEmpty) {
                        setState(() {
                          _paths.removeLast();
                          _paints.removeLast();
                        });
                      }
                    },
                  ),
                  IconButton(
                    tooltip: UiText.t('clear'),
                    icon: const Icon(Icons.delete),
                    onPressed: () => setState(() {
                      _paths.clear();
                      _paints.clear();
                    }),
                  ),
                ],
                PopupMenuButton<String>(
                  tooltip: UiText.t('toolMenu'),
                  onSelected: (v) async {
                    switch (v) {
                      case 'color':
                        if (!guideOnly) _pickColor(context);
                        break;
                      case 'width':
                        if (!guideOnly) _pickWidth(context);
                        break;
                      case 'save':
                        await _saveAsPng(context, glyph);
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'color', child: Text(UiText.t('pickColor'))),
                    PopupMenuItem(value: 'width', child: Text(UiText.t('pickWidth'))),
                    PopupMenuItem(value: 'save',  child: Text(UiText.t('savePng'))),
                  ],
                ),
              ],
            ),
            body: Column(
              children: [
                if (guideOnly)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: Text(
                      UiText.t('compositeNote'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: RepaintBoundary(
                        key: _captureKey,
                        child: Stack(
                          children: [
                            if (_showGrid)
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _GridPainter(
                                    color: Colors.black12,
                                    gridSize: 32,
                                  ),
                                ),
                              ),
                            if (_showGuide && guide != null)
                              Positioned.fill(
                                child: Opacity(
                                  opacity: 0.45,
                                  child: Image.asset(guide, fit: BoxFit.contain),
                                ),
                              ),
                            if (!guideOnly)
                              Positioned.fill(
                                child: GestureDetector(
                                  onPanStart: (d) {
                                    final p = Paint()
                                      ..style = PaintingStyle.stroke
                                      ..strokeWidth = _strokeWidth
                                      ..strokeCap = StrokeCap.round
                                      ..strokeJoin = StrokeJoin.round
                                      ..color = _strokeColor;
                                    _current = Path()
                                      ..moveTo(d.localPosition.dx, d.localPosition.dy);
                                    setState(() {
                                      _paths.add(_current!);
                                      _paints.add(p);
                                    });
                                  },
                                  onPanUpdate: (d) => setState(() {
                                    _current?.lineTo(
                                      d.localPosition.dx,
                                      d.localPosition.dy,
                                    );
                                  }),
                                  onPanEnd: (_) => _current = null,
                                  child: RepaintBoundary(
                                    child: CustomPaint(
                                      painter: _StrokePainter(_paths, _paints),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Text(
                    guideOnly ? UiText.t('compositeNote') : UiText.t('tip'),
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ----- Pickers -----
  Future<void> _pickColor(BuildContext context) async {
    final colors = <Color>[
      Colors.blueGrey,
      Colors.black87,
      Colors.redAccent,
      Colors.blueAccent,
      Colors.green,
      Colors.purple,
      Colors.orange,
    ];
    await showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              Text(
                UiText.t('pickColor'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              for (final c in colors)
                GestureDetector(
                  onTap: () {
                    setState(() => _strokeColor = c);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black12,
                        width: _strokeColor == c ? 3 : 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickWidth(BuildContext context) async {
    double tempWidth = _strokeWidth;
    await showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                UiText.t('pickWidth'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Text(UiText.t('thin')),
                  Expanded(
                    child: Slider(
                      min: 2,
                      max: 18,
                      divisions: 16,
                      value: tempWidth,
                      label: tempWidth.toStringAsFixed(0),
                      onChanged: (v) => setState(() => tempWidth = v),
                    ),
                  ),
                  Text(UiText.t('thick')),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(UiText.t('cancel')),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _strokeWidth = tempWidth);
                      _savePrefs();
                      Navigator.pop(context);
                    },
                    child: Text(UiText.t('ok')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----- Save PNG -----
  Future<void> _saveAsPng(BuildContext context, String glyph) async {
    try {
      final boundary =
      _captureKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final dir = await getApplicationDocumentsDirectory();
      final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final safe = glyph.runes.map((r) => r.toRadixString(16)).join('_');
      final file = File('${dir.path}/writing_${safe}_$ts.png');

      await file.writeAsBytes(bytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${UiText.t("saved")}: ${file.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${UiText.t("failed")}: $e')),
      );
    }
  }
}

// ================= Painters =================

class _StrokePainter extends CustomPainter {
  _StrokePainter(this.paths, this.paints);
  final List<Path> paths;
  final List<Paint> paints;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < paths.length; i++) {
      canvas.drawPath(paths[i], paints[i]);
    }
  }

  @override
  bool shouldRepaint(covariant _StrokePainter old) => true;
}

class _GridPainter extends CustomPainter {
  _GridPainter({this.gridSize = 32, this.color = Colors.black12});
  final double gridSize;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;

    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }

    final cp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color.withOpacity(0.5);
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      cp,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      cp,
    );
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) =>
      old.gridSize != gridSize || old.color != color;
}

// ───────── Intents 정의 ─────────
class _UndoIntent extends Intent { const _UndoIntent(); }
class _SaveIntent extends Intent { const _SaveIntent(); }
class _ToggleGridIntent extends Intent { const _ToggleGridIntent(); }
class _ToggleGuideIntent extends Intent { const _ToggleGuideIntent(); }
