import 'package:flutter/material.dart';

import '../core/theme/app_effects.dart';

/// 氛围背景 —— 对应原型 frame 内的三个 blur(70px) 光斑：
/// A：主题色 53% 透明度，左上；B：主题色 33%，右中；C：中性灰，底部。
/// 颜色变化以 900ms 标准缓动过渡（原型 transition: background 900ms）。
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: color),
      duration: AppMotion.ambient,
      curve: AppMotion.standard,
      builder: (context, c, _) {
        final tint = c ?? color;
        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFF0D0B10)),
            // 光斑层（原型 inset:-20%，用超采样定位近似）
            Positioned.fill(
              child: LayoutBuilder(builder: (context, box) {
                final w = box.maxWidth;
                final h = box.maxHeight;
                Widget orb(
                    double left, double top, double ow, double oh, Color oc) {
                  return Positioned(
                    left: left,
                    top: top,
                    width: ow,
                    height: oh,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [oc, oc.withValues(alpha: 0)],
                          stops: const [0.0, 0.7],
                        ),
                      ),
                    ),
                  );
                }

                return Stack(children: [
                  orb(-w * .18, h * .02, w * 1.05, h * .56,
                      tint.withValues(alpha: .53)),
                  orb(w * .30, h * .28, w * .95, h * .54,
                      tint.withValues(alpha: .33)),
                  orb(w * .02, h * .62, w * 1.15, h * .54,
                      const Color(0xFF787880).withValues(alpha: .22)),
                ]);
              }),
            ),
            // 底部径向压暗（原型 radial-gradient at 50% 110%）
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, 1.2),
                  radius: 1.1,
                  colors: [Color(0x8C000000), Color(0x00000000)],
                  stops: [0.0, 0.6],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
