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

  /// 上传表单专用：前段克制推进，约 70% 后加速完成。
  static const Curve lateAcceleration = Cubic(0.55, 0.05, 0.82, 0.18);

  static const Duration fast = Duration(milliseconds: 140);
  static const Duration base = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 420);

  /// 氛围背景色过渡 900ms（原型内联）
  static const Duration ambient = Duration(milliseconds: 900);
}
