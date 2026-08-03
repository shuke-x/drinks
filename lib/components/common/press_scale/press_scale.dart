import 'package:flutter/material.dart';

import '../../../core/interaction/app_feedback.dart';
import '../../../core/theme/app_effects.dart';

/// 为自定义控件提供统一按压缩放、长按反馈与减少动态效果支持。
class PressScale extends StatefulWidget {
  /// 创建一个按压反馈容器。
  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.96,
    this.longPressScale = 0.935,
  });

  /// 接收按压反馈的子组件。
  final Widget child;

  /// 轻点回调；为 `null` 时不注册轻点手势。
  final VoidCallback? onTap;

  /// 长按回调；为 `null` 时不执行长按业务操作。
  final VoidCallback? onLongPress;

  /// 普通按压时的缩放比例，默认 0.96。
  final double scale;

  /// 长按成立后的缩放比例，默认 0.935。
  final double longPressScale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;
  bool _longPress = false;

  void _release() {
    if (!_down && !_longPress) return;
    setState(() {
      _down = false;
      _longPress = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: widget.onTap != null,
      enabled: widget.onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown:
            widget.onTap == null ? null : (_) => setState(() => _down = true),
        onTapCancel: _release,
        onTapUp: widget.onTap == null ? null : (_) => _release(),
        onLongPressStart: widget.onTap == null && widget.onLongPress == null
            ? null
            : (_) {
                setState(() {
                  _down = true;
                  _longPress = true;
                });
                AppFeedback.impact();
              },
        onLongPressEnd: widget.onTap == null && widget.onLongPress == null
            ? null
            : (_) => _release(),
        onLongPress: widget.onLongPress,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale:
              _longPress ? widget.longPressScale : (_down ? widget.scale : 1),
          duration: reduceMotion ? Duration.zero : AppMotion.fast,
          curve: reduceMotion ? Curves.linear : AppMotion.standard,
          child: widget.child,
        ),
      ),
    );
  }
}
