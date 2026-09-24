import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// 全应用统一的无文案加载反馈。
///
/// 以主题色光晕、琥珀流光和前后遮挡模拟莫比乌斯带，不需要额外动画资源。
class AppLoadingView extends StatefulWidget {
  const AppLoadingView({super.key, this.size = 76, this.themeColor});

  final double size;
  final Color? themeColor;

  @override
  State<AppLoadingView> createState() => _AppLoadingViewState();
}

class _AppLoadingViewState extends State<AppLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = .25;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return Semantics(
      container: true,
      liveRegion: true,
      label: l10n?.processing ?? 'Processing',
      child: ExcludeSemantics(
        child: Center(
          child: RepaintBoundary(
            child: SizedBox.square(
              dimension: widget.size,
              child: CustomPaint(
                painter: _MobiusPainter(
                  animation: _controller,
                  themeColor: widget.themeColor ?? const Color(0xFF7B61FF),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobiusPainter extends CustomPainter {
  _MobiusPainter({required this.animation, required this.themeColor})
      : super(repaint: animation);

  final Animation<double> animation;
  final Color themeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * .34;
    final halfWidth = size.shortestSide * .105;
    const segments = 72;
    final phase = animation.value * math.pi * 2;

    // 酒液主题色在带子背后形成柔和光晕。
    canvas.drawCircle(
      center,
      size.shortestSide * .48,
      Paint()
        ..shader = RadialGradient(
          colors: [
            themeColor.withValues(alpha: .34),
            themeColor.withValues(alpha: 0),
          ],
          stops: const [.0, 1],
        ).createShader(Rect.fromCircle(
          center: center,
          radius: size.shortestSide * .48,
        )),
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    // 保持横向双叶轮廓，仅做轻微摆动；整圈旋转会让带面退化成圆环。
    canvas.rotate(math.sin(phase) * .07);

    // 先画后侧、再画前侧，使中央交叉处能读出带面的前后关系。
    for (final front in [false, true]) {
      for (var i = 0; i < segments; i++) {
        final a0 = i / segments * math.pi * 2;
        if ((math.sin(a0) > 0) != front) continue;
        final a1 = (i + 1) / segments * math.pi * 2;
        // 带面宽度随扭转位置略微变化，增强“翻面”的体积感。
        final width0 = halfWidth * (.82 + .18 * math.cos(a0 - phase));
        final width1 = halfWidth * (.82 + .18 * math.cos(a1 - phase));
        final path = Path()
          ..moveTo(
              _point(a0, -width0, radius).dx, _point(a0, -width0, radius).dy)
          ..lineTo(_point(a0, width0, radius).dx, _point(a0, width0, radius).dy)
          ..lineTo(_point(a1, width1, radius).dx, _point(a1, width1, radius).dy)
          ..lineTo(
              _point(a1, -width1, radius).dx, _point(a1, -width1, radius).dy)
          ..close();
        // 琥珀金高光沿带面持续流动，前侧略亮以体现遮挡层级。
        final sweep = (math.sin(a0 - phase) + 1) / 2;
        final side = (math.cos(a0 / 2) + 1) / 2;
        final base = Color.lerp(themeColor, const Color(0xFF241B36), .52)!;
        const amber = Color(0xFFFFC66D);
        final color = Color.lerp(base, amber, .18 + .56 * sweep + .18 * side)!;
        canvas.drawPath(path, Paint()..color = color);
      }
    }
    canvas.restore();
  }

  Offset _point(double angle, double width, double radius) {
    // 横向双叶路径在中心交叉；带宽的半次翻转表现莫比乌斯带的单面特征。
    final x = radius * math.cos(angle);
    final y = radius * .42 * math.sin(angle * 2);
    final dx = -radius * math.sin(angle);
    final dy = radius * .84 * math.cos(angle * 2);
    final length = math.sqrt(dx * dx + dy * dy);
    final twist = math.cos(angle / 2);
    return Offset(
        x - dy / length * width * twist, y + dx / length * width * twist);
  }

  @override
  bool shouldRepaint(covariant _MobiusPainter oldDelegate) => false;
}
