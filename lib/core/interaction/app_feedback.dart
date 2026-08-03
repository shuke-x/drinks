import 'package:flutter/services.dart';

/// 全应用触觉反馈语义表。
///
/// 只在离散且有意义的状态变化上触发，避免把每次点击都变成振动噪声。
abstract final class AppFeedback {
  static Future<void> selection() => HapticFeedback.selectionClick();

  static Future<void> impact() => HapticFeedback.lightImpact();

  static Future<void> success() => HapticFeedback.mediumImpact();

  static Future<void> warning() => HapticFeedback.heavyImpact();
}
