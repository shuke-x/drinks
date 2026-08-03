import 'package:flutter/material.dart';

/// 详情、编辑等二级页面共用的不透明深色基底。
///
/// 不使用透明度或全屏模糊，避免推入页面时透出一级页面的视差运动，
/// 同时避免与 UIKit platform view 的合成层产生矩形遮挡。
class FrostedPageOverlay extends StatelessWidget {
  const FrostedPageOverlay({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
        key: const ValueKey('secondary_page_background'),
        color: const Color(0xFF0D0B10),
        child: child,
      );
}
