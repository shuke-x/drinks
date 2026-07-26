import 'dart:ui';

import 'package:flutter/material.dart';

/// 详情、编辑等全屏覆盖页共用的毛玻璃幕布。
///
/// 路由本身保持透明，覆盖层负责模糊和遮光，从而保留底层页面的空间感。
class FrostedPageOverlay extends StatelessWidget {
  const FrostedPageOverlay({
    super.key,
    required this.child,
    this.blur = 13,
    this.opacity = .72,
  });

  final Widget child;
  final double blur;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: ColoredBox(
        color: const Color(0xFF0D0B10).withOpacity(opacity),
        child: child,
      ),
    );
  }
}
