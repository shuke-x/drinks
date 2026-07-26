import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cocktail.dart';

/// 相邻卡片的水平步距：316px 卡宽外加 20px 可见间距。
const double kDeckStep = 336;

/// 手势灵敏度独立于视觉步距，避免加大卡片间距后拖动变迟缓。
const double kDeckDragStep = 240;

/// 弧线半径（原型 R = 6000）。
const double kDeckArcRadius = 6000;

/// Next 页弧形卡组物理控制器 —— 1:1 移植设计原型的 JS 引擎：
/// · 空闲巡航：速度以 0.18 卡/秒为目标平滑趋近
/// · 拖拽：独立灵敏度 + 0.55 系数 lerp 跟手，松手速度钳制 ±2.6
/// · 抽选：2500ms，缓动 1-(1-k)^3.2，最后 18% 叠加 sin 过冲(0.055)
class DeckController extends ChangeNotifier {
  /// 浮点卡片索引（可为任意实数，取模映射到列表）。
  double pos = 0;
  double vel = 0;

  bool dragging = false;
  bool spinning = false;

  /// 抽中后金色光晕（1.5s）与结果面板对应的酒 id。
  String? landedId;
  String? sheetId;

  /// 巡航暂停（详情/上传打开或不在 Next 页时置 true）。
  bool paused = false;

  double? _aim;
  double _startPos = 0;
  double _startX = 0;
  bool _moved = false;
  bool _noClick = false;
  Timer? _clickTimer;
  Timer? _landTimer;

  _SpinAnim? _spin;
  Cocktail? _winner;

  bool get suppressClick => _noClick;

  /// 覆盖页打开时停止巡航并立即通知卡组重绘。
  void pause() {
    paused = true;
    dragging = false;
    _aim = null;
    notifyListeners();
  }

  /// 覆盖页关闭或路由返回后恢复巡航，确保不会停留在暂停帧。
  void resume() {
    paused = false;
    if (!spinning) vel = math.max(vel, .18);
    notifyListeners();
  }

  /// 每帧驱动（dt 秒，钳制在原型同款 [0.001, 0.05] 区间）。
  void tick(double dt) {
    dt = dt.clamp(0.001, 0.05);

    if (dragging) {
      if (_aim != null) {
        final prev = pos;
        pos += (_aim! - pos) * 0.55;
        vel = (pos - prev) / dt;
      }
      notifyListeners();
      return;
    }

    final spin = _spin;
    if (spin != null) {
      final k = math.min(
          1.0,
          (DateTime.now().microsecondsSinceEpoch - spin.t0) /
              (spin.durMs * 1000));
      final e = 1 - math.pow(1 - k, 3.2).toDouble();
      final over =
          math.sin(((k - 0.82) / 0.18).clamp(0.0, 1.0) * math.pi) * 0.055;
      pos = spin.from + (spin.to - spin.from) * e + over;
      if (k >= 1) {
        pos = spin.to;
        _spin = null;
        _finishSpin();
      }
      notifyListeners();
      return;
    }

    if (paused) return;

    // 空闲巡航。
    const cruise = .18;
    vel += (cruise - vel) * math.min(1.0, dt * 2.2);
    pos += vel * dt;
    notifyListeners();
  }

  // ---- 拖拽（对应原型 onDown / onMove / onUp）----

  void onDragStart(double clientX) {
    if (spinning) return;
    dragging = true;
    _moved = false;
    _startX = clientX;
    _startPos = pos;
    _aim = pos;
    vel = 0;
    _spin = null;
    notifyListeners();
  }

  void onDragUpdate(double clientX) {
    if (!dragging) return;
    final dx = clientX - _startX;
    if (dx.abs() > 5) _moved = true;
    _aim = _startPos - dx / kDeckDragStep;
  }

  void onDragEnd() {
    if (!dragging) return;
    dragging = false;
    _aim = null;
    vel = vel.clamp(-2.6, 2.6);
    if (_moved) {
      _noClick = true;
      _clickTimer?.cancel();
      _clickTimer =
          Timer(const Duration(milliseconds: 240), () => _noClick = false);
    }
    notifyListeners();
  }

  // ---- 抽选（对应原型 spin / finishSpin）----

  void spin(List<Cocktail> list) {
    if (spinning || list.isEmpty) return;
    final len = list.length;
    final pick = math.Random().nextInt(len);
    final base = pos.round();
    final cur = ((base % len) + len) % len;
    // 至少两整圈 + 落到目标卡（原型公式）。
    final to = base + len * 2 + (((pick - cur) % len) + len) % len;
    _winner = list[pick];
    vel = 0;
    _spin = _SpinAnim(
      from: pos,
      to: to.toDouble(),
      t0: DateTime.now().microsecondsSinceEpoch,
      durMs: 2500,
    );
    spinning = true;
    sheetId = null;
    landedId = null;
    notifyListeners();
  }

  void _finishSpin() {
    spinning = false;
    landedId = _winner?.id;
    sheetId = _winner?.id;
    _landTimer?.cancel();
    _landTimer = Timer(const Duration(milliseconds: 1500), () {
      landedId = null;
      notifyListeners();
    });
    notifyListeners();
  }

  void dismissSheet() {
    sheetId = null;
    notifyListeners();
  }

  /// 当前居中卡索引（原型 curIndex()）。
  int currentIndex(int length) {
    if (length == 0) return 0;
    final n = pos.round();
    return ((n % length) + length) % length;
  }

  @override
  void dispose() {
    _clickTimer?.cancel();
    _landTimer?.cancel();
    super.dispose();
  }
}

class _SpinAnim {
  final double from;
  final double to;
  final int t0; // microseconds
  final int durMs;
  const _SpinAnim(
      {required this.from,
      required this.to,
      required this.t0,
      required this.durMs});
}

/// 全局唯一控制器：切 Tab 后卡组位置保留。
final deckControllerProvider = ChangeNotifierProvider<DeckController>((ref) {
  return DeckController();
});
