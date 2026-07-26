import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_effects.dart';
import '../core/theme/app_typography.dart';

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

/// 毛玻璃圆形图标按钮（右上角加号 / 返回 / 关闭）。
class GlassCircleButton extends StatelessWidget {
  const GlassCircleButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 42,
    this.iconSize = 18,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.glassFill10,
              border: Border.all(color: Colors.white.withOpacity(.18)),
            ),
            child: Icon(icon,
                size: iconSize,
                color: iconColor ?? Colors.white.withOpacity(.75)),
          ),
        ),
      ),
    );
  }
}

/// 胶囊标签（分类 chips / 卡片 tag）。
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
            size: fontSize, weight: FontWeight.w600, color: fg, height: 1.0);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.slow,
        curve: AppMotion.spring,
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
        border: Border.all(color: borderColor ?? Colors.white.withOpacity(.16)),
      ),
      child: Text(
        label,
        style: mono
            ? AppType.mono(size: fontSize, color: fg)
            : AppType.sans(
                size: fontSize,
                weight: FontWeight.w600,
                color: fg,
                height: 1.0),
      ),
    );
  }
}

/// 按压缩放反馈（原型 press-scale 0.96 / 140ms）。
class PressScale extends StatefulWidget {
  const PressScale(
      {super.key, required this.child, this.onTap, this.scale = 0.96});

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: AppMotion.fast,
        curve: AppMotion.spring,
        child: widget.child,
      ),
    );
  }
}

/// 入场动画（原型 riseIn / fadeUp）。
class RiseIn extends StatelessWidget {
  const RiseIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 26,
    this.duration = const Duration(milliseconds: 550),
  });

  final Widget child;
  final Duration delay;
  final double offset;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration + delay,
      curve: Interval(
        delay.inMilliseconds / (duration + delay).inMilliseconds,
        1,
        curve: AppMotion.spring,
      ),
      // BackdropFilter 不支持被不透明度图层包裹；入场只保留位移。
      builder: (context, t, c) =>
          Transform.translate(offset: Offset(0, offset * (1 - t)), child: c),
      child: child,
    );
  }
}
