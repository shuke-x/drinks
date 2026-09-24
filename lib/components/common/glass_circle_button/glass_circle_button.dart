import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../apple_liquid_glass_button/apple_liquid_glass_button.dart';
import '../press_scale/press_scale.dart';

/// 小面积系统操作使用的圆形 Liquid Glass 图标按钮。
class GlassCircleButton extends StatelessWidget {
  /// 创建一个圆形图标按钮。
  const GlassCircleButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 42,
    this.iconSize = 18,
    this.iconColor,
    this.backgroundColor,
    this.semanticLabel,
    this.appleSystemImageName,
  })  : assert(size > 0),
        assert(iconSize > 0);

  /// Flutter fallback 使用的图标。
  final IconData icon;

  /// 点击回调；为 `null` 时按钮处于禁用状态。
  final VoidCallback? onTap;

  /// 可见圆形的直径，默认 42pt。
  ///
  /// 实际点击区域始终不小于 44pt；大于 44 时点击区域随之增大。
  final double size;

  /// Flutter fallback 图标尺寸，默认 18pt。
  final double iconSize;

  /// 图标前景色；省略时根据对比度使用白色。
  final Color? iconColor;

  /// 原生 Liquid Glass 的可选表面底色。
  ///
  /// Flutter fallback 仍使用与详情页收藏按钮一致的玻璃渐变。
  final Color? backgroundColor;

  /// VoiceOver 与其他辅助技术读取的操作名称。
  final String? semanticLabel;

  /// iOS 原生 Liquid Glass 使用的 SF Symbol 名称。
  ///
  /// 省略时所有平台都使用 Flutter fallback。
  final String? appleSystemImageName;

  @override
  Widget build(BuildContext context) {
    final highContrast = MediaQuery.highContrastOf(context);
    final hitSize = math.max(44.0, size);
    final circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: highContrast ? const Color(0xFF35323B) : null,
        gradient: highContrast
            ? null
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: .16),
                  AppColors.glassFill10,
                ],
              ),
        border: Border.all(
          color: Colors.white.withValues(alpha: highContrast ? .64 : .22),
        ),
        boxShadow: highContrast
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .22),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Icon(
        icon,
        size: iconSize,
        color:
            iconColor ?? Colors.white.withValues(alpha: highContrast ? 1 : .88),
      ),
    );
    final content = ExcludeSemantics(
      child: PressScale(
        onTap: onTap,
        scale: .97,
        child: SizedBox.square(
          dimension: hitSize,
          child: Center(
            child: ClipOval(
              child: highContrast
                  ? circle
                  : BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: circle,
                    ),
            ),
          ),
        ),
      ),
    );
    final fallback = onTap == null && semanticLabel == null
        ? content
        : Semantics(
            button: true,
            enabled: onTap != null,
            label: semanticLabel,
            child: content,
          );
    if (appleSystemImageName == null) return fallback;
    return AppleLiquidGlassSwitcher(
      fallback: fallback,
      nativeBuilder: (_) => SizedBox.square(
        dimension: hitSize,
        child: AppleLiquidGlassButton(
          onPressed: onTap,
          systemImageName: appleSystemImageName,
          semanticLabel: semanticLabel,
          foregroundColor: iconColor ?? Colors.white,
          backgroundColor: backgroundColor,
          imagePadding: 0,
        ),
      ),
    );
  }
}
