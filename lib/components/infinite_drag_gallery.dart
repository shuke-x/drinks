import 'package:flutter/material.dart';

import 'drag_gallery_list.dart';

/// Backward-compatible name for [DragGalleryList].
@Deprecated('Use DragGalleryList instead.')
class InfiniteDragGallery extends StatelessWidget {
  const InfiniteDragGallery({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.itemExtent = 112,
    this.gap = 12,
    this.friction = 0.06,
    this.minFlingVelocity = 80,
    this.maxFlingVelocity = 5000,
    this.dragScale = 0.86,
    this.initialOffset = 0,
    this.backgroundColor = Colors.black,
    this.padding = const EdgeInsets.symmetric(vertical: 24),
    this.borderRadius = BorderRadius.zero,
    this.onInteractionStart,
    this.onInteractionEnd,
    this.semanticLabel,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double itemExtent;
  final double gap;
  final double friction;
  final double minFlingVelocity;
  final double maxFlingVelocity;
  final double dragScale;
  final double initialOffset;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final VoidCallback? onInteractionStart;
  final VoidCallback? onInteractionEnd;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => DragGalleryList(
        itemCount: itemCount,
        itemBuilder: itemBuilder,
        itemExtent: itemExtent,
        gap: gap,
        friction: friction,
        minFlingVelocity: minFlingVelocity,
        maxFlingVelocity: maxFlingVelocity,
        dragScale: dragScale,
        initialOffset: initialOffset,
        backgroundColor: backgroundColor,
        padding: padding,
        borderRadius: borderRadius,
        onInteractionStart: onInteractionStart,
        onInteractionEnd: onInteractionEnd,
        semanticLabel: semanticLabel,
      );
}
