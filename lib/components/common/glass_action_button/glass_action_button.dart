import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../apple_liquid_glass_button/apple_liquid_glass_button.dart';
import '../press_scale/press_scale.dart';

/// 操作按钮中图标相对于文案的位置。
enum GlassActionIconPlace {
  /// 图标显示在文案之前；在当前 LTR 界面中位于左侧。
  left,

  /// 图标显示在文案之后；在当前 LTR 界面中位于右侧。
  right,
}

/// 与底部 TabBar 同语言的胶囊操作按钮。
class GlassActionButton extends StatelessWidget {
  /// 创建一个自适应 Apple Liquid Glass 操作按钮。
  const GlassActionButton({
    super.key,
    required this.label,
    this.icon,
    this.iconPlace = GlassActionIconPlace.left,
    this.onTap,
    this.width,
    this.height,
    this.danger = false,
    this.appleSystemImageName,
    this.prominent = false,
    this.tintColor,
    this.backgroundColor,
    this.gradientColors,
    this.fontSize = 13.5,
  })  : assert(width == null || width >= 0),
        assert(height == null || height >= 44),
        assert(fontSize > 0),
        assert(gradientColors == null || gradientColors.length >= 2);

  /// 按钮显示的文案，同时作为原生按钮的默认无障碍语义标签。
  final String label;

  /// Flutter fallback 使用的可选图标，位置由 [iconPlace] 控制。
  final IconData? icon;

  /// 图标相对于 [label] 的位置，默认 [GlassActionIconPlace.left]。
  ///
  /// 同时作用于 Flutter [icon] 和原生 [appleSystemImageName]。
  final GlassActionIconPlace iconPlace;

  /// 点击回调；为 `null` 时原生和 Flutter 按钮都处于禁用状态。
  final VoidCallback? onTap;

  /// 外部指定的按钮宽度；省略时根据内容自适应。
  ///
  /// 百分比宽度应由 [FractionallySizedBox] 或 [LayoutBuilder] 提供约束。
  final double? width;

  /// 外部指定的按钮高度，最小 44pt；省略时使用默认最小高度 48pt。
  final double? height;

  /// 是否使用危险语义红色，适用于删除、注销等高风险操作。
  final bool danger;

  /// iOS 原生 Liquid Glass 使用的 SF Symbol 名称。
  ///
  /// Flutter fallback 对应图标由 [icon] 提供。
  final String? appleSystemImageName;

  /// 是否在支持的 iOS 版本使用系统 `prominentGlass` 样式。
  final bool prominent;

  /// Optional surface tint for the frosted fallback background.
  final Color? tintColor;

  /// Surface color for the frosted glass button.
  final Color? backgroundColor;

  /// Optional top-to-bottom surface gradient for the frosted fallback.
  final List<Color>? gradientColors;

  /// Button title font size in logical points.
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final accent = danger ? AppColors.danger : Colors.white;
    final surface = backgroundColor ?? tintColor ?? accent;
    final iconOnRight = iconPlace == GlassActionIconPlace.right;
    final minimumHeight = height ?? 48;

    List<Widget> contentChildren({Color? color}) {
      final contentColor = color ?? Colors.white;
      final iconWidget = icon == null
          ? null
          : Icon(
              icon,
              key: const ValueKey('glass_action_icon'),
              size: 17,
              color: contentColor,
            );
      final labelWidget = Text(
        label,
        key: const ValueKey('glass_action_label'),
        style: AppType.sans(
          size: fontSize,
          weight: FontWeight.w700,
          color: contentColor,
          height: 1,
        ),
      );
      if (iconWidget == null) return [labelWidget];
      return iconOnRight
          ? [labelWidget, const SizedBox(width: 16), iconWidget]
          : [iconWidget, const SizedBox(width: 16), labelWidget];
    }

    final native = ConstrainedBox(
      constraints: BoxConstraints(minHeight: minimumHeight),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ExcludeSemantics(
            child: Opacity(
              opacity: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: contentChildren(),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: AppleLiquidGlassButton(
              onPressed: onTap,
              label: label,
              systemImageName: appleSystemImageName,
              semanticLabel: label,
              foregroundColor: accent,
              backgroundColor: backgroundColor ?? tintColor,
              prominent: prominent,
              fontSize: fontSize,
              imageTrailing: iconOnRight,
            ),
          ),
        ],
      ),
    );
    final fallback = PressScale(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            constraints: BoxConstraints(minHeight: minimumHeight),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: gradientColors == null
                    ? [
                        surface.withValues(alpha: danger ? .24 : .22),
                        surface.withValues(alpha: danger ? .12 : .10),
                      ]
                    : [
                        for (var index = 0;
                            index < gradientColors!.length;
                            index++)
                          gradientColors![index].withValues(
                            alpha: danger ? .28 : (index == 0 ? .72 : .44),
                          ),
                      ],
              ),
              border: Border.all(
                color: surface.withValues(alpha: danger ? .62 : .34),
              ),
              boxShadow: danger
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: .16),
                        blurRadius: 24,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: contentChildren(color: accent),
            ),
          ),
        ),
      ),
    );
    // Native UIButton.Configuration.glass does not expose a gradient surface.
    // Keep gradient buttons on the Flutter frosted renderer so the visual
    // treatment is identical on iOS and other platforms.
    if (gradientColors != null) {
      return SizedBox(width: width, height: height, child: fallback);
    }
    return SizedBox(
      width: width,
      height: height,
      child: AppleLiquidGlassSwitcher(
        nativeBuilder: (_) => native,
        fallback: fallback,
      ),
    );
  }
}
