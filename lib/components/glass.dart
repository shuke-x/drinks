import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/interaction/app_feedback.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_effects.dart';
import '../core/theme/app_typography.dart';

// Compatibility exports. Reusable controls live under components/common.
export 'common/glass_action_button/glass_action_button.dart';
export 'common/glass_circle_button/glass_circle_button.dart';
export 'common/press_scale/press_scale.dart';

/// 毛玻璃卡片 —— 原型规格：
/// rgba(255,255,255,.08~.11) 填充 + blur(22~30) + 1px 白 15% 描边 + 大圆角。
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.radius = 26,
    this.blur = 24,
    this.fillOpacity = .09,
    this.borderOpacity = .15,
    this.padding = const EdgeInsets.all(18),
    this.shadow = true,
  });

  final Widget child;
  final double radius;
  final double blur;
  final double fillOpacity;
  final double borderOpacity;
  final EdgeInsetsGeometry padding;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(.42),
                  blurRadius: 44,
                  offset: const Offset(0, 18),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur / 2, sigmaY: blur / 2),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(fillOpacity),
              borderRadius: BorderRadius.circular(radius),
              border:
                  Border.all(color: Colors.white.withOpacity(borderOpacity)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 可交互的胶囊选择项。
class GlassChip extends StatelessWidget {
  const GlassChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.mono = false,
    this.fontSize = 13,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool mono;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final fg =
        selected ? const Color(0xFF0D0B10) : Colors.white.withOpacity(.75);
    final style = mono
        ? AppType.mono(size: fontSize, color: fg)
        : AppType.sans(
            size: fontSize,
            weight: FontWeight.w600,
            color: fg,
            height: 1,
          );
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: label,
      child: GestureDetector(
        excludeFromSemantics: true,
        onTap: onTap == null
            ? null
            : () {
                AppFeedback.selection();
                onTap?.call();
              },
        child: AnimatedContainer(
          duration: reduceMotion ? Duration.zero : AppMotion.base,
          curve: reduceMotion ? Curves.linear : AppMotion.standard,
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            color: selected
                ? Colors.white.withOpacity(.94)
                : Colors.white.withOpacity(.08),
            border: Border.all(
              color: selected
                  ? Colors.white.withOpacity(.94)
                  : AppColors.glassBorder,
            ),
          ),
          child: Text(label, style: style),
        ),
      ),
    );
  }
}

/// 静态信息小胶囊（详情 chips / 卡片角标）。
class InfoPill extends StatelessWidget {
  const InfoPill({
    super.key,
    required this.label,
    this.mono = false,
    this.fontSize = 10.5,
    this.fill,
    this.borderColor,
    this.textColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  });

  final String label;
  final bool mono;
  final double fontSize;
  final Color? fill;
  final Color? borderColor;
  final Color? textColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final fg = textColor ?? Colors.white.withOpacity(.85);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: fill ?? Colors.white.withOpacity(.12),
        border: Border.all(
          color: borderColor ?? Colors.white.withOpacity(.16),
        ),
      ),
      child: Text(
        label,
        style: mono
            ? AppType.mono(size: fontSize, color: fg)
            : AppType.sans(
                size: fontSize,
                weight: FontWeight.w600,
                color: fg,
                height: 1,
              ),
      ),
    );
  }
}

/// 入场位移动画（原型 riseIn / fadeUp）。
class RiseIn extends StatelessWidget {
  const RiseIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 26,
    this.duration = const Duration(milliseconds: 550),
    this.followRouteOnExit = true,
  });

  final Widget child;
  final Duration delay;
  final double offset;
  final Duration duration;
  final bool followRouteOnExit;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final routeAnimation = ModalRoute.of(context)?.animation;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration + delay,
      curve: Interval(
        delay.inMilliseconds / (duration + delay).inMilliseconds,
        1,
        curve: AppMotion.spring,
      ),
      // BackdropFilter 不支持被不透明度图层包裹；入场只保留位移。
      builder: (context, t, c) {
        if (routeAnimation == null || !followRouteOnExit) {
          return Transform.translate(
            offset: Offset(0, offset * (1 - t)),
            child: c,
          );
        }
        return AnimatedBuilder(
          animation: routeAnimation,
          child: c,
          builder: (context, child) {
            final routeT = AppMotion.overlayEnter.transform(
              routeAnimation.value.clamp(0.0, 1.0),
            );
            final progress = t * routeT;
            return Transform.translate(
              offset: Offset(0, offset * (1 - progress)),
              child: child,
            );
          },
        );
      },
      child: child,
    );
  }
}
