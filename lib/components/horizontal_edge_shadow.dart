import 'package:flutter/material.dart';

/// Softens the clipped edges of a horizontal scroller without intercepting
/// gestures. An edge is illuminated only while more content exists beyond it.
class HorizontalEdgeShadow extends StatefulWidget {
  const HorizontalEdgeShadow({
    super.key,
    required this.child,
    this.width = 22,
  });

  final Widget child;
  final double width;

  @override
  State<HorizontalEdgeShadow> createState() => _HorizontalEdgeShadowState();
}

class _HorizontalEdgeShadowState extends State<HorizontalEdgeShadow> {
  bool _showLeft = false;
  bool _showRight = true;

  void _updateMetrics(ScrollMetrics metrics) {
    if (metrics.axis != Axis.horizontal) return;
    final showLeft = metrics.extentBefore > 1;
    final showRight = metrics.extentAfter > 1;
    if (showLeft == _showLeft && showRight == _showRight) return;
    setState(() {
      _showLeft = showLeft;
      _showRight = showRight;
    });
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    _updateMetrics(notification.metrics);
    return false;
  }

  bool _handleMetricsNotification(ScrollMetricsNotification notification) {
    _updateMetrics(notification.metrics);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          NotificationListener<ScrollMetricsNotification>(
            onNotification: _handleMetricsNotification,
            child: NotificationListener<ScrollNotification>(
              onNotification: _handleScrollNotification,
              child: widget.child,
            ),
          ),
          _EdgeLight(
            key: const ValueKey('horizontal_edge_shadow_left'),
            alignment: Alignment.centerLeft,
            visible: _showLeft,
            width: widget.width,
            reduceMotion: reduceMotion,
          ),
          _EdgeLight(
            key: const ValueKey('horizontal_edge_shadow_right'),
            alignment: Alignment.centerRight,
            visible: _showRight,
            width: widget.width,
            reduceMotion: reduceMotion,
          ),
        ],
      ),
    );
  }
}

class _EdgeLight extends StatelessWidget {
  const _EdgeLight({
    super.key,
    required this.alignment,
    required this.visible,
    required this.width,
    required this.reduceMotion,
  });

  final Alignment alignment;
  final bool visible;
  final double width;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final isLeft = alignment == Alignment.centerLeft;
    final colors = [
      Colors.black.withValues(alpha: .28),
      Colors.black.withValues(alpha: .10),
      Colors.transparent,
    ];
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: Container(
            width: width,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
                end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
                colors: colors,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .12),
                  blurRadius: 14,
                  spreadRadius: -2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
