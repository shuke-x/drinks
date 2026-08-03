import 'package:flutter/animation.dart';

/// 动效 tokens —— 对应设计稿 tokens/effects.css。
class AppMotion {
  AppMotion._();

  /// cubic-bezier(0.32, 0.72, 0, 1) — 标准过渡
  static const Curve standard = Cubic(0.32, 0.72, 0, 1);

  /// cubic-bezier(0.16, 1, 0.3, 1) — ease-out
  static const Curve easeOut = Cubic(0.16, 1, 0.3, 1);

  /// cubic-bezier(0.34, 1.3, 0.64, 1) — 轻微弹簧
  static const Curve spring = Cubic(0.34, 1.3, 0.64, 1);

  /// 覆盖页开关使用同一条对称曲线，正放、反放的速度感完全一致。
  static const Curve overlayEnter = Cubic(0.65, 0, 0.35, 1);

  /// 与 [overlayEnter] 相同；保留独立语义名称便于路由配置阅读。
  static const Curve overlayExit = Cubic(0.65, 0, 0.35, 1);

  /// 黄金比例节奏：前 61.8% 克制推进，末段快速落位。
  static const Curve fibonacciIn = Cubic(0.62, 0.0, 0.82, 0.18);

  /// 关闭时使用对应的减速曲线，让反向运动完整可见。
  static const Curve fibonacciOut = Cubic(0.18, 0.82, 0.38, 1.0);

  static const Duration fast = Duration(milliseconds: 140);
  static const Duration base = Duration(milliseconds: 240);
  static const Duration fibonacci = Duration(milliseconds: 200);
  static const Duration detailOverlay = Duration(milliseconds: 280);
  static const Duration editorOverlay = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 280);

  /// 氛围背景色过渡 900ms（原型内联）
  static const Duration ambient = Duration(milliseconds: 600);
}
