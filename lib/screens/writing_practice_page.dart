// lib/screens/writing_practice_page.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart'; // rootBundle, 단축키
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

// 경로 유틸
import 'package:path/path.dart' as p;

import 'package:korean_writing_app_new/data_loader/stroke_assets.dart';
import 'package:korean_writing_app_new/i18n/ui_texts.dart';
import 'package:korean_writing_app_new/i18n/language_state.dart';
import 'package:korean_writing_app_new/tts_helpers.dart';

// 인앱 결제/광고 제거 상태
import 'package:korean_writing_app_new/ads/ads_purchase_state.dart';

// 배너 광고 위젯
import 'package:korean_writing_app_new/ads/banner_ad_widget.dart';

// ✅ AdMob 보상형 광고 서비스 (실제 광고 연동)
import 'package:korean_writing_app_new/services/admob_service.dart';

// ───────── UI 텍스트 안전 폴백 헬퍼 ─────────
String _tr(String key, String fallback) {
  final s = UiText.t(key);
  return (s.trim().isNotEmpty && s != key) ? s : fallback;
}

// ───────── 저장 키 ─────────
const _kShowGuide = 'draw.showGuide';
const _kShowGrid = 'draw.showGrid';
const _kWidth = 'draw.strokeWidth';

// ✅ 하루 무료 저장 정책용 키
const _kDailyFreeSaves = 3;
const _kDailySaveDate = 'draw.dailySaveDate';
const _kDailySaveCount = 'draw.dailySaveCount';

// ✅ 광고 1회 언락 상태 키 (오늘 한 번 광고를 보면 이후 무제한 저장)
const _kAdUnlockDate = 'draw.adUnlockDate';

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

  // ---- 가이드 이미지 해석/확인 결과 ----
  String? _guideAssetPath; // 실제 존재 확인된 가이드 경로
  bool _guideResolved = false; // 존재 확인 완료 여부

  // ✅ 하루 무료 저장 한도 상태
  int _freeSavesLeft = _kDailyFreeSaves;
  bool _quotaLoaded = false;

  // ✅ 오늘 광고 1회 언락 여부
  bool _adUnlockedToday = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _resolveGuideFor(widget.charGlyph); // context 의존 없음
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // 기존 설정 불러오기
    final showGuide = prefs.getBool(_kShowGuide) ?? true;
    final showGrid = prefs.getBool(_kShowGrid) ?? true;
    final strokeWidth = prefs.getDouble(_kWidth) ?? 6;

    // ✅ 하루 무료 저장 카운터 로직
    final today = DateFormat('yyyyMMdd').format(DateTime.now());
    final lastDate = prefs.getString(_kDailySaveDate);
    int usedCount = prefs.getInt(_kDailySaveCount) ?? 0;

    if (lastDate != today) {
      // 새로운 날: 카운터 리셋
      usedCount = 0;
      await prefs.setString(_kDailySaveDate, today);
      await prefs.setInt(_kDailySaveCount, usedCount);
      // 날짜가 바뀌면 광고 언락도 자동 초기화
      await prefs.remove(_kAdUnlockDate);
    }

    final remaining =
    (_kDailyFreeSaves - usedCount).clamp(0, _kDailyFreeSaves);

    // ✅ 오늘 광고 언락 여부
    final adUnlockDate = prefs.getString(_kAdUnlockDate);
    final unlocked = (adUnlockDate == today);

    if (!mounted) return;
    setState(() {
      _showGuide = showGuide;
      _showGrid = showGrid;
      _strokeWidth = strokeWidth;
      _freeSavesLeft = remaining;
      _quotaLoaded = true;
      _adUnlockedToday = unlocked;
    });
  }

  Future<void> _savePrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kShowGuide, _showGuide);
    await p.setBool(_kShowGrid, _showGrid);
    await p.setDouble(_kWidth, _strokeWidth);
  }

  // ✅ 저장 1회 사용 처리
  Future<void> _markSaveUsed() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyyMMdd').format(DateTime.now());
    final lastDate = prefs.getString(_kDailySaveDate);
    int usedCount = prefs.getInt(_kDailySaveCount) ?? 0;

    if (lastDate != today) {
      usedCount = 0;
    }

    usedCount++;
    await prefs.setString(_kDailySaveDate, today);
    await prefs.setInt(_kDailySaveCount, usedCount);

    if (!mounted) return;
    setState(() {
      _freeSavesLeft =
          (_kDailyFreeSaves - usedCount).clamp(0, _kDailyFreeSaves);
    });
  }

  // ✅ 오늘은 광고를 한 번 봐서 이후에는 광고 없이 무제한 저장
  Future<void> _setAdUnlockedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyyMMdd').format(DateTime.now());
    await prefs.setString(_kAdUnlockDate, today);

    if (!mounted) return;
    setState(() {
      _adUnlockedToday = true;
    });
  }

  // 남은 무료 저장 안내
  void _showQuotaInfoSnackBar(BuildContext context) {
    if (!mounted) return;

    String msg;

    if (_adUnlockedToday) {
      // 이미 광고 1회로 언락된 상태
      msg = UiText.t('adUnlockedToday') != 'adUnlockedToday'
          ? UiText.t('adUnlockedToday')
          : '오늘은 이미 광고를 한 번 보셨습니다.\n'
          '이후 저장은 광고 없이 이용하실 수 있습니다.';
    } else {
      final left = _freeSavesLeft;
      if (left > 0) {
        // i18n 키가 준비되어 있으면 사용, 아니면 기본 한국어
        if (UiText.t('freeSaveLeft') != 'freeSaveLeft') {
          msg = UiText.t('freeSaveLeft').replaceAll('{n}', '$left');
        } else {
          msg = '오늘 남은 무료 저장 횟수: $left회';
        }
      } else {
        if (UiText.t('noFreeSaveLeft') != 'noFreeSaveLeft') {
          msg = UiText.t('noFreeSaveLeft');
        } else {
          msg = '오늘의 무료 저장 3회를 모두 사용했습니다.\n'
              '추가 저장은 광고 시청 후 가능합니다.';
        }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // 광고 시청 의사 확인 다이얼로그 (실제 보상 광고용)
  Future<bool> _confirmWatchAd(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          UiText.t('watchAdToSaveTitle') != 'watchAdToSaveTitle'
              ? UiText.t('watchAdToSaveTitle')
              : '광고를 보고 저장하시겠어요?',
        ),
        content: Text(
          UiText.t('watchAdToSaveBody') != 'watchAdToSaveBody'
              ? UiText.t('watchAdToSaveBody')
              : '오늘의 무료 저장 3회를 모두 사용했습니다.\n'
              '추가로 이미지를 저장하려면 짧은 광고를 한 번 시청해야 합니다.\n'
              '오늘 한 번만 광고를 보면, 이후에는 광고 없이 저장하실 수 있습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              UiText.t('cancel') != 'cancel' ? UiText.t('cancel') : '취소',
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              UiText.t('ok') != 'ok' ? UiText.t('ok') : '확인',
            ),
          ),
        ],
      ),
    ) ??
        false;
  }

  // ✅ 실제 보상형 광고 호출 (AdmobService 사용)
  Future<bool> _showRewardedAdReal(BuildContext context) async {
    // AdmobService 에서 로딩이 안 돼 있으면 false 반환
    final ok = await AdmobService.instance.showRewardedAd(
      onUserEarnedReward: (_) {
        // 여기서는 "보상 지급" 로직이 필요 없고
        // 광고를 끝까지 봤다는 것 자체가 '추가 저장 언락' 역할을 합니다.
      },
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            UiText.t('rewardAdNotReady') != 'rewardAdNotReady'
                ? UiText.t('rewardAdNotReady')
                : '광고가 아직 준비되지 않았습니다. 잠시 후 다시 시도해 주세요.',
          ),
        ),
      );
    }

    return ok;
  }

  // ✅ 저장 요청 핸들러:
  //  - 하루 3회 무료 저장
  //  - 이후에는 광고 1번만 보면 그날은 무제한 저장
  Future<void> _handleSaveRequest(BuildContext context, String glyph) async {
    // 🔹 광고 제거 구매자 or 오늘 이미 광고 언락된 상태 → 무제한 저장
    final adsState = context.read<AdsPurchaseState>();
    await adsState.ensureLoaded(); // 안전하게 초기화

    if (adsState.isAdsRemoved || _adUnlockedToday) {
      await _saveAsPng(context, glyph);
      return;
    }

    // 🔹 무료 저장 남아 있을 때 (아직 오늘 광고 언락도 안 한 상태)
    if (_freeSavesLeft > 0) {
      await _saveAsPng(context, glyph);
      await _markSaveUsed();
      _showQuotaInfoSnackBar(context);
      return;
    }

    // 🔹 무료 저장 없음 → 오늘 첫 광고 제안
    final agree = await _confirmWatchAd(context);
    if (!agree) return;

    // 🔹 실제 보상형 광고 호출
    final adOk = await _showRewardedAdReal(context);
    if (!adOk) return;

    // ✅ 광고를 끝까지 봤으니, 오늘 하루는 광고 없이 무제한 저장 허용
    await _setAdUnlockedToday();

    // 그리고 이번 시도도 바로 저장
    await _saveAsPng(context, glyph);
  }

  // ───────── 가이드 경로 해결(존재 확인 포함) ─────────
  Future<void> _resolveGuideFor(String glyph) async {
    // 1) StrokeAssets.get(glyph) 우선(자모/글자에서 주로 사용)
    final primary = StrokeAssets.get(glyph);

    // 2) 음절(단어/문장) 호환 후보들 생성
    final raw = glyph.trim();
    final key = raw
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('·', '')
        .replaceAll('.', '');
    final syllables = key.split('');
    final keyUnderscore = syllables.join('_');

    final candidates = <String>[
      if (primary != null) primary,
      // 권장 기본 경로(음절)
      'assets/strokes/syllables/$key.png',
      'assets/strokes/syllables/stroke_$key.png',
      'assets/strokes/syllables/$keyUnderscore.png',
      'assets/strokes/syllables/stroke_$keyUnderscore.png',
      // 과거 이미지 경로 호환
      'assets/images/strokes/syllables/$key.png',
      'assets/images/strokes/syllables/stroke_$key.png',
      'assets/images/strokes/syllables/$keyUnderscore.png',
      'assets/images/strokes/syllables/stroke_$keyUnderscore.png',
    ];

    String? found;
    for (final pth in candidates) {
      try {
        await rootBundle.load(pth);
        found = pth;
        break;
      } catch (_) {
        // 다음 후보로
      }
    }

    if (!mounted) return;
    setState(() {
      _guideAssetPath = found; // 없으면 null
      _guideResolved = true;
    });
  }

  // ───────── 단축키용 Intent ─────────
  static const _undoIntent = _UndoIntent();
  static const _saveIntent = _SaveIntent();
  static const _toggleGridIntent = _ToggleGridIntent();
  static const _toggleGuideIntent = _ToggleGuideIntent();

  // ───────── 안내문(다국어) ─────────
  static const Map<String, String> _hintTopI18n = {
    'ko': '위의 메뉴를 사용해 격자/가이드 보기, 되돌리기, 지우기, 색·두께 선택, 저장을 할 수 있습니다.',
    'en':
    'Use the toolbar above to toggle grid/guide, undo, clear, pick color & width, and save.',
    'ja': '上部のツールバーでグリッド/ガイド表示、取り消し、消去、色と太さの選択、保存ができます。',
    'zh': '使用顶部工具栏可切换网格/指南、撤销、清除、选择颜色与粗细，并保存。',
    'vi':
    'Dùng thanh công cụ trên để bật/tắt lưới/hướng dẫn, hoàn tác, xóa, chọn màu & độ dày, và lưu.',
    'fr':
    'Utilisez la barre d’outils ci-dessus pour afficher/masquer la grille/guide, annuler, effacer, choisir la couleur & l’épaisseur, et enregistrer.',
    'de':
    'Mit der oberen Symbolleiste kannst du Raster/Guide ein-/ausblenden, rückgängig machen, löschen, Farbe & Strichstärke wählen und speichern.',
    'es':
    'Usa la barra de herramientas superior para alternar rejilla/guía, deshacer, borrar, elegir color y grosor, y guardar.',
    'ru':
    'Используйте верхнюю панель, чтобы включать/выключать сетку/подсказку, отменять, очищать, выбирать цвет и толщину, и сохранять.',
    'mn':
    'Дээд хэрэгслээс тор/зааврыг асаах·унтраах, буцаах, арилгах, өнгө ба зузаан сонгох, хадгалах боломжтой.',
  };

  static const Map<String, String> _hintBottomI18n = {
    'ko': '손가락이나 펜으로 따라 그려 보세요.',
    'en': 'Trace with your finger or stylus.',
    'ja': '指やペンでなぞってみましょう。',
    'zh': '请用手指或手写笔描画。',
    'vi': 'Hãy tô theo bằng ngón tay hoặc bút.',
    'fr': 'Tracez avec votre doigt ou votre stylet.',
    'de': 'Zeichne mit deinem Finger oder Stift nach.',
    'es': 'Repasa con tu dedo o un lápiz óptico.',
    'ru': 'Обводите пальцем или стилусом.',
    'mn': 'Хуруу эсвэл үзгээр даган зур.',
  };

  String _pickHint(
      Map<String, String> m, String uiTextKey, String fallbackKey) {
    final fromUiText = UiText.t(uiTextKey);
    if (fromUiText.trim().isNotEmpty) return fromUiText;

    final code = LanguageState.I.code.split('-').first;
    return m[code] ?? m[fallbackKey]!;
  }

  @override
  Widget build(BuildContext context) {
    final glyph = widget.charGlyph;

    final shortcuts = <LogicalKeySet, Intent>{
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ):
      _undoIntent,
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
      _saveIntent,
      LogicalKeySet(LogicalKeyboardKey.keyG): _toggleGridIntent,
      LogicalKeySet(LogicalKeyboardKey.keyH): _toggleGuideIntent,
    };

    final topHint = _pickHint(_hintTopI18n, 'practiceHintTop', 'en');
    final bottomHint = _pickHint(_hintBottomI18n, 'practiceHintBottom', 'en');

    // 가이드 표시 여부 판단: 존재 확인 완료 후 경로가 있을 때만 이미지 사용
    final hasGuideImage = _guideResolved && _guideAssetPath != null;

    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          _UndoIntent: CallbackAction<_UndoIntent>(onInvoke: (_) {
            if (_paths.isNotEmpty) {
              setState(() {
                _paths.removeLast();
                _paints.removeLast();
              });
            }
            return null;
          }),
          _SaveIntent: CallbackAction<_SaveIntent>(onInvoke: (_) {
            _handleSaveRequest(context, glyph);
            return null;
          }),
          _ToggleGridIntent:
          CallbackAction<_ToggleGridIntent>(onInvoke: (_) {
            setState(() => _showGrid = !_showGrid);
            _savePrefs();
            return null;
          }),
          _ToggleGuideIntent:
          CallbackAction<_ToggleGuideIntent>(onInvoke: (_) {
            setState(() => _showGuide = !_showGuide);
            _savePrefs();
            return null;
          }),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              title: Text('${UiText.t("practice")}  •  $glyph'),
              actions: [
                IconButton(
                  tooltip: UiText.t('listen'),
                  icon: const Icon(Icons.volume_up),
                  onPressed: () => AppTts.speakGlyphOrText(glyph),
                ),
                IconButton(
                  tooltip: UiText.t('toggleGuide'),
                  icon: Icon(
                    _showGuide ? Icons.visibility : Icons.visibility_off,
                  ),
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
                PopupMenuButton<String>(
                  tooltip: UiText.t('toolMenu'),
                  onSelected: (v) async {
                    switch (v) {
                      case 'color':
                        _pickColor(context);
                        break;
                      case 'width':
                        _pickWidth(context);
                        break;
                      case 'save':
                        await _handleSaveRequest(context, glyph);
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'color',
                      child: Text(UiText.t('pickColor')),
                    ),
                    PopupMenuItem(
                      value: 'width',
                      child: Text(UiText.t('pickWidth')),
                    ),
                    PopupMenuItem(
                      value: 'save',
                      child: Text(UiText.t('savePng')),
                    ),
                  ],
                ),
              ],
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Text(
                    topHint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Colors.black54,
                    ),
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

                            // ✅ 가이드: 이미지가 있으면 이미지, 없으면 흐린 텍스트
                            if (_showGuide && hasGuideImage)
                              Positioned.fill(
                                child: Opacity(
                                  opacity: 0.45,
                                  child: Image.asset(
                                    _guideAssetPath!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              )
                            else if (_showGuide)
                              const Positioned.fill(
                                child: _BigGlyphBackground(
                                  glyph: '',
                                  opacity: 0.14,
                                ),
                              ),

                            // 워터마크 텍스트(이미지 없을 때 표시)
                            if (_showGuide && !hasGuideImage)
                              Positioned.fill(
                                child: IgnorePointer(
                                  ignoring: true,
                                  child: Center(
                                    child: FittedBox(
                                      fit: BoxFit.contain,
                                      child: Text(
                                        widget.charGlyph,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 600,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black
                                              .withValues(alpha: 0.08),
                                          height: 1.0,
                                          letterSpacing: 0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // 드로잉 레이어
                            Positioned.fill(
                              child: GestureDetector(
                                onPanStart: (d) {
                                  final pnt = Paint()
                                    ..style = PaintingStyle.stroke
                                    ..strokeWidth = _strokeWidth
                                    ..strokeCap = StrokeCap.round
                                    ..strokeJoin = StrokeJoin.round
                                    ..color = _strokeColor;
                                  _current = Path()
                                    ..moveTo(
                                      d.localPosition.dx,
                                      d.localPosition.dy,
                                    );
                                  setState(() {
                                    _paths.add(_current!);
                                    _paints.add(pnt);
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
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                  child: Text(
                    bottomHint,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),

            // ─────────────────────────────
            // 하단 배너 광고
            // ─────────────────────────────
            bottomNavigationBar: const SafeArea(
              top: false,
              child: BannerAdArea(),
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

  // ─────── 공용 PNG 저장(임시 대체: 모바일은 앱 전용 폴더) ───────
  Future<Map<String, dynamic>> _savePngFallback(
      Uint8List bytes, String fileName) async {
    final safeName = fileName.endsWith('.png') ? fileName : '$fileName.png';

    Directory base;
    if (Platform.isAndroid || Platform.isIOS) {
      base = await getApplicationDocumentsDirectory();
    } else {
      base = (await getDownloadsDirectory()) ??
          await getApplicationDocumentsDirectory();
    }

    final saveDir = Directory(p.join(base.path, 'KoreanWritingApp'));
    await saveDir.create(recursive: true);

    final path = p.join(saveDir.path, safeName);
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);

    return {'isSuccess': true, 'filePath': path};
  }

  // ----- Save PNG (안정 확장판) -----
  Future<void> _saveAsPng(BuildContext context, String glyph) async {
    try {
      // 1) 캡처용 RenderObject 확보(없으면 안전하게 종료)
      final boundaryContext = _captureKey.currentContext;
      if (boundaryContext == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _tr(
                'captureNotReady',
                '화면이 아직 완전히 준비되지 않았습니다. 잠시 후 다시 시도해 주세요.',
              ),
            ),
          ),
        );
        return;
      }

      final boundary =
      boundaryContext.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List bytes = byteData!.buffer.asUint8List();

      // 2) 파일명
      final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final hex = glyph.isEmpty
          ? 'writing'
          : glyph.runes.map((r) => r.toRadixString(16)).join('_');
      final fileName = 'practice_${hex}_$ts.png';

      String message;

      // 3) 플랫폼별 저장
      if (Platform.isAndroid || Platform.isIOS) {
        // 갤러리 대신 앱 전용 폴더에 저장(빌드 통과용). 추후 media_store_plus로 교체 가능.
        final res = await _savePngFallback(bytes, fileName);
        final ok = res['isSuccess'] == true;

        if (ok) {
          // ✅ 다국어 저장 안내 (모바일)
          final line1 = _tr(
            'saveImageResultLine1',
            '쓰기 연습 이미지를 저장했어요.',
          );
          final line2 = _tr(
            'saveImageResultLine2',
            '휴대폰의 "내 파일" 또는 파일 관리자 앱을 열고\n'
                '"KoreanWritingApp" 폴더를 찾아보세요.',
          );
          final fileLabelTemplate =
          _tr('saveImageResultFileName', '파일 이름: {name}');
          final fileLabel =
          fileLabelTemplate.replaceAll('{name}', fileName);

          message = '$line1\n$line2\n$fileLabel';
        } else {
          message = _tr('failed', '저장에 실패했습니다.');
        }
      } else {
        // Windows/macOS/Linux: Downloads 폴더 우선, 없으면 Documents
        Directory? base;
        bool usedDownloads = false;
        try {
          base = await getDownloadsDirectory();
          if (base != null) {
            usedDownloads = true;
          }
        } catch (_) {}
        base ??= await getApplicationDocumentsDirectory();

        final saveDir = Directory(p.join(base.path, 'KoreanWritingApp'));
        await saveDir.create(recursive: true);

        final file = File(p.join(saveDir.path, fileName));
        await file.writeAsBytes(bytes, flush: true);

        final baseLabel =
        usedDownloads ? '다운로드(Downloads)' : '문서(Documents)';

        // ✅ 학생에게 보여줄 안내 문구 (데스크톱)
        final desktopTemplate = UiText.t('savePngDesktopSuccess');
        if (desktopTemplate != 'savePngDesktopSuccess' &&
            desktopTemplate.trim().isNotEmpty) {
          message = desktopTemplate
              .replaceAll('{baseLabel}', baseLabel)
              .replaceAll('{fileName}', fileName);
        } else {
          message = '쓰기 연습 이미지를 저장했어요.\n'
              '"$baseLabel" 폴더 안의 "KoreanWritingApp" 폴더에 저장되었습니다.\n'
              '파일 이름: $fileName';
        }

        // ignore: avoid_print
        print('Saved PNG: ${file.path}');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_tr("failed", "저장에 실패했습니다.")}: $e',
          ),
        ),
      );
    }
  }
}

// ================= Painters / Widgets =================

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
    final pnt = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;

    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), pnt);
    }
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), pnt);
    }

    final cp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color.withValues(alpha: 0.5);
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

/// 가이드 이미지가 없을 때 배경에 큰 글자를 그려주는 위젯
class _BigGlyphBackground extends StatelessWidget {
  const _BigGlyphBackground({required this.glyph, this.opacity = 0.12});
  final String glyph;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: Text(
            glyph,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 600,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              height: 1.0,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

// ───────── Intents 정의 ─────────
class _UndoIntent extends Intent {
  const _UndoIntent();
}

class _SaveIntent extends Intent {
  const _SaveIntent();
}

class _ToggleGridIntent extends Intent {
  const _ToggleGridIntent();
}

class _ToggleGuideIntent extends Intent {
  const _ToggleGuideIntent();
}
