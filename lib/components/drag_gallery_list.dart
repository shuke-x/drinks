import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

double _animeIn2(double value) => value * value;

double _animeOut2(double value) {
  final inverse = 1 - value;
  return 1 - inverse * inverse;
}

/// An infinitely repeating horizontal gallery with direct drag and momentum.
///
/// The motion model follows the same principles commonly used in Anime.js:
/// direct manipulation while the pointer is down, interruptible timelines,
/// and eased/physical continuation after release. Flutter's native
/// [AnimationController] and [FrictionSimulation] are used so motion stays
/// synchronized with the engine frame scheduler.
///
/// Every item must have the same [itemExtent]. Only the items needed to cover
/// the viewport (plus a small paint buffer) are built.
class DragGalleryList extends StatefulWidget {
  const DragGalleryList({
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
    this.clipBehavior = Clip.antiAlias,
    this.dragStartBehavior = DragStartBehavior.start,
    this.hitTestBehavior = HitTestBehavior.opaque,
    this.mouseCursor = SystemMouseCursors.grab,
    this.draggingMouseCursor = SystemMouseCursors.grabbing,
    this.enabled = true,
    this.onInteractionStart,
    this.onInteractionEnd,
    this.semanticLabel,
  })  : assert(itemCount >= 0),
        assert(itemExtent > 0),
        assert(gap >= 0),
        assert(friction > 0),
        assert(minFlingVelocity >= 0),
        assert(maxFlingVelocity > 0),
        assert(dragScale > 0 && dragScale <= 1);

  /// Number of logical items repeated by the infinite track.
  ///
  /// A value of zero renders an empty, non-interactive viewport.
  final int itemCount;

  /// Builds an item for a logical index in the range `0..itemCount - 1`.
  ///
  /// The same logical item can appear more than once when one cycle is
  /// narrower than the viewport, so children should not rely on unique keys
  /// derived from the logical index alone.
  final IndexedWidgetBuilder itemBuilder;

  /// Fixed horizontal extent of every item, in logical pixels.
  final double itemExtent;

  /// Empty horizontal space between adjacent items, in logical pixels.
  final double gap;

  /// Drag coefficient passed to [FrictionSimulation].
  ///
  /// Larger values coast farther. Values around `0.06`–`0.12` generally
  /// produce a smooth, controllable gallery interaction; `0.06` feels tighter
  /// while `0.12` feels more slippery.
  final double friction;

  /// Minimum release velocity required to start inertial scrolling, in
  /// logical pixels per second.
  final double minFlingVelocity;

  /// Maximum drag or release velocity used by the motion model, in logical
  /// pixels per second.
  final double maxFlingVelocity;

  /// Scale applied while the pointer directly controls the gallery.
  ///
  /// While the gallery moves left, the leading cards on the left stay larger
  /// and the trailing cards toward the right become progressively smaller.
  /// Moving right mirrors the effect. The gradient remains active through
  /// release momentum and fades out when movement stops.
  /// Set this to `1` to disable the directional tail.
  final double dragScale;

  /// Initial translation of the repeating track, in logical pixels.
  ///
  /// Positive values move items right; negative values move them left. This
  /// value is read when the state is created and is not a controlled offset.
  final double initialOffset;

  /// Color painted behind the gallery items.
  final Color backgroundColor;

  /// Insets between the viewport edge and the item track.
  final EdgeInsetsGeometry padding;

  /// Corner radius of the gallery background and clipping boundary.
  final BorderRadiusGeometry borderRadius;

  /// How content outside [borderRadius] is clipped.
  ///
  /// Set to [Clip.none] when the parent already provides the required clip.
  final Clip clipBehavior;

  /// Defines when a horizontal drag begins relative to the first pointer
  /// event. This matches [GestureDetector.dragStartBehavior].
  final DragStartBehavior dragStartBehavior;

  /// Controls how the gallery participates in pointer hit testing.
  final HitTestBehavior hitTestBehavior;

  /// Mouse cursor shown while the gallery is idle.
  final MouseCursor mouseCursor;

  /// Mouse cursor shown while the pointer is actively dragging the gallery.
  final MouseCursor draggingMouseCursor;

  /// Whether drag gestures and accessibility scroll actions are enabled.
  final bool enabled;

  /// Called once when direct dragging or an accessibility scroll begins.
  final VoidCallback? onInteractionStart;

  /// Called once after the interaction and any release momentum have ended.
  final VoidCallback? onInteractionEnd;

  /// Optional accessibility label for the gallery container.
  final String? semanticLabel;

  @override
  State<DragGalleryList> createState() => _DragGalleryListState();
}

class _DragGalleryListState extends State<DragGalleryList>
    with TickerProviderStateMixin {
  static const _velocitySmoothingSeconds = .028;
  static const _semanticStepDuration = Duration(milliseconds: 320);
  static const _semanticStepCurve = Curves.easeOutCubic;

  late final AnimationController _position;
  late final AnimationController _depth;
  late final Listenable _trackRepaint;
  final ValueNotifier<bool> _pointerDown = ValueNotifier(false);
  bool _interactionActive = false;
  bool _reduceMotion = false;
  double _motionDirection = 0;
  double _visualVelocity = 0;
  double _coastStartSpeed = 0;
  double _coastStartStrength = 0;
  Duration? _lastDragTimestamp;
  int _motionGeneration = 0;

  double get _stride => widget.itemExtent + widget.gap;

  @override
  void initState() {
    super.initState();
    _position = AnimationController.unbounded(
      vsync: this,
      value: widget.initialOffset,
    );
    _depth = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 110),
    );
    _trackRepaint = Listenable.merge([_position, _depth]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextReduceMotion = MediaQuery.disableAnimationsOf(context);
    if (nextReduceMotion == _reduceMotion) return;

    _reduceMotion = nextReduceMotion;
    if (_reduceMotion) _depth.value = 0;
    if (_reduceMotion && _position.isAnimating) {
      _cancelMotion();
      _endInteraction();
    }
  }

  @override
  void didUpdateWidget(covariant DragGalleryList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled && !widget.enabled) {
      _pointerDown.value = false;
      _visualVelocity = 0;
      _cancelMotion();
      _endInteraction();
    }
    final geometryChanged = oldWidget.itemCount != widget.itemCount ||
        oldWidget.itemExtent != widget.itemExtent ||
        oldWidget.gap != widget.gap;
    if (!geometryChanged) return;

    _cancelMotion();
    _endInteraction();
  }

  @override
  void dispose() {
    _pointerDown.dispose();
    _depth.dispose();
    _position.dispose();
    super.dispose();
  }

  void _cancelMotion() {
    _motionGeneration++;
    _position.stop();
  }

  void _beginInteraction() {
    if (_interactionActive) return;
    _interactionActive = true;
    if (!_reduceMotion) _depth.forward();
    widget.onInteractionStart?.call();
  }

  void _endInteraction() {
    if (!_interactionActive) return;
    _interactionActive = false;
    if (!_reduceMotion) _depth.reverse();
    widget.onInteractionEnd?.call();
  }

  void _handleDragStart(DragStartDetails details) {
    _cancelMotion();
    _motionDirection = 0;
    _visualVelocity = 0;
    _coastStartSpeed = 0;
    _coastStartStrength = 0;
    _lastDragTimestamp = details.sourceTimeStamp;
    _beginInteraction();
    _pointerDown.value = true;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final delta = details.delta.dx;
    if (delta != 0) {
      final timestamp = details.sourceTimeStamp;
      var elapsedSeconds = 1 / 60;
      if (timestamp != null && _lastDragTimestamp != null) {
        final elapsedMicroseconds =
            (timestamp - _lastDragTimestamp!).inMicroseconds;
        if (elapsedMicroseconds > 0 && elapsedMicroseconds < 100000) {
          elapsedSeconds = elapsedMicroseconds / Duration.microsecondsPerSecond;
        }
      }
      _lastDragTimestamp = timestamp;

      final sampledVelocity = (delta / elapsedSeconds)
          .clamp(-widget.maxFlingVelocity, widget.maxFlingVelocity)
          .toDouble();
      final blend = 1 - math.exp(-elapsedSeconds / _velocitySmoothingSeconds);
      _visualVelocity += (sampledVelocity - _visualVelocity) * blend;
      if (_visualVelocity.abs() > 1) {
        _motionDirection = _visualVelocity.sign;
      }
    }
    _position.value += delta;
  }

  void _handleDragEnd(DragEndDetails details) {
    _pointerDown.value = false;

    final rawVelocity = details.primaryVelocity ?? 0;
    final velocity = rawVelocity
        .clamp(-widget.maxFlingVelocity, widget.maxFlingVelocity)
        .toDouble();
    if (velocity != 0) {
      final directT = (_visualVelocity.abs() / (_stride * 11)).clamp(0.0, 1.0);
      _coastStartSpeed = velocity.abs();
      _coastStartStrength = _animeOut2(directT);
      _motionDirection = velocity.sign;
      _visualVelocity = velocity;
    }
    _lastDragTimestamp = null;

    if (_reduceMotion || velocity.abs() < widget.minFlingVelocity) {
      _visualVelocity = 0;
      _endInteraction();
      return;
    }

    final generation = ++_motionGeneration;
    _position
        .animateWith(
      FrictionSimulation(widget.friction, _position.value, velocity),
    )
        .whenCompleteOrCancel(() {
      if (!mounted || generation != _motionGeneration) return;
      _visualVelocity = 0;
      _endInteraction();
    });
  }

  void _handleDragCancel() {
    _pointerDown.value = false;
    _cancelMotion();
    _visualVelocity = 0;
    _coastStartSpeed = 0;
    _coastStartStrength = 0;
    _lastDragTimestamp = null;
    _endInteraction();
  }

  void _animateSemanticStep(double direction) {
    if (widget.itemCount == 0) return;

    _cancelMotion();
    _motionDirection = direction.sign;
    _coastStartSpeed = _stride / _semanticStepDuration.inMilliseconds * 1000;
    _coastStartStrength = _animeOut2(
      (_coastStartSpeed / (_stride * 11)).clamp(0.0, 1.0),
    );
    _beginInteraction();
    final target = _position.value + (_stride * direction);

    if (_reduceMotion) {
      _position.value = target;
      _endInteraction();
      return;
    }

    final generation = ++_motionGeneration;
    _position
        .animateTo(
      target,
      duration: _semanticStepDuration,
      curve: _semanticStepCurve,
    )
        .whenCompleteOrCancel(() {
      if (!mounted || generation != _motionGeneration) return;
      _endInteraction();
    });
  }

  @override
  Widget build(BuildContext context) {
    final decoratedContent = DecoratedBox(
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: widget.borderRadius,
      ),
      child: Padding(
        padding: widget.padding,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (widget.itemCount == 0) return const SizedBox.expand();
            assert(
              constraints.hasBoundedWidth,
              'DragGalleryList requires a bounded width.',
            );

            final visibleItemCount =
                (constraints.maxWidth / _stride).ceil() + 4;
            return _DragGalleryFlow(
              position: _position,
              depth: _depth,
              repaint: _trackRepaint,
              motionDirection: () => _motionDirection,
              motionSpeed: () => _position.isAnimating
                  ? _position.velocity.abs()
                  : _visualVelocity.abs(),
              coastStartSpeed: () => _coastStartSpeed,
              coastStartStrength: () => _coastStartStrength,
              itemCount: widget.itemCount,
              visibleItemCount: visibleItemCount,
              itemExtent: widget.itemExtent,
              stride: _stride,
              minimumScale: widget.dragScale,
              itemBuilder: widget.itemBuilder,
            );
          },
        ),
      ),
    );

    final resolvedRadius =
        widget.borderRadius.resolve(Directionality.of(context));
    final Widget content;
    if (widget.clipBehavior == Clip.none) {
      content = decoratedContent;
    } else if (resolvedRadius == BorderRadius.zero) {
      content = ClipRect(
        clipBehavior: widget.clipBehavior,
        child: decoratedContent,
      );
    } else {
      content = ClipRRect(
        borderRadius: resolvedRadius,
        clipBehavior: widget.clipBehavior,
        child: decoratedContent,
      );
    }

    final gestureDetector = GestureDetector(
      behavior: widget.hitTestBehavior,
      dragStartBehavior: widget.dragStartBehavior,
      onHorizontalDragStart:
          !widget.enabled || widget.itemCount == 0 ? null : _handleDragStart,
      onHorizontalDragUpdate:
          !widget.enabled || widget.itemCount == 0 ? null : _handleDragUpdate,
      onHorizontalDragEnd:
          !widget.enabled || widget.itemCount == 0 ? null : _handleDragEnd,
      onHorizontalDragCancel:
          !widget.enabled || widget.itemCount == 0 ? null : _handleDragCancel,
      child: content,
    );

    final interactive = ValueListenableBuilder<bool>(
      valueListenable: _pointerDown,
      child: gestureDetector,
      builder: (context, pointerDown, child) => MouseRegion(
        cursor: pointerDown ? widget.draggingMouseCursor : widget.mouseCursor,
        child: child,
      ),
    );

    return Semantics(
      label: widget.semanticLabel,
      container: widget.semanticLabel != null,
      explicitChildNodes: true,
      onIncrease: !widget.enabled || widget.itemCount == 0
          ? null
          : () => _animateSemanticStep(-1),
      onDecrease: !widget.enabled || widget.itemCount == 0
          ? null
          : () => _animateSemanticStep(1),
      child: interactive,
    );
  }
}

/// Rebuilds children only when the virtual leading slot changes. Every frame
/// between those boundaries is handled as a paint-only [Flow] transform.
class _DragGalleryFlow extends StatefulWidget {
  const _DragGalleryFlow({
    required this.position,
    required this.depth,
    required this.repaint,
    required this.motionDirection,
    required this.motionSpeed,
    required this.coastStartSpeed,
    required this.coastStartStrength,
    required this.itemCount,
    required this.visibleItemCount,
    required this.itemExtent,
    required this.stride,
    required this.minimumScale,
    required this.itemBuilder,
  });

  final Animation<double> position;
  final Animation<double> depth;
  final Listenable repaint;
  final double Function() motionDirection;
  final double Function() motionSpeed;
  final double Function() coastStartSpeed;
  final double Function() coastStartStrength;
  final int itemCount;
  final int visibleItemCount;
  final double itemExtent;
  final double stride;
  final double minimumScale;
  final IndexedWidgetBuilder itemBuilder;

  @override
  State<_DragGalleryFlow> createState() => _DragGalleryFlowState();
}

class _DragGalleryFlowState extends State<_DragGalleryFlow> {
  late int _firstVirtualIndex;

  double get _shift => widget.position.value;

  int get _leadingIndex => (-_shift / widget.stride).floor() - 1;

  @override
  void initState() {
    super.initState();
    _firstVirtualIndex = _leadingIndex;
    widget.position.addListener(_handlePositionChanged);
  }

  @override
  void didUpdateWidget(covariant _DragGalleryFlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.position != widget.position) {
      oldWidget.position.removeListener(_handlePositionChanged);
      widget.position.addListener(_handlePositionChanged);
    }
    _firstVirtualIndex = _leadingIndex;
  }

  @override
  void dispose() {
    widget.position.removeListener(_handlePositionChanged);
    super.dispose();
  }

  void _handlePositionChanged() {
    final nextIndex = _leadingIndex;
    if (nextIndex == _firstVirtualIndex || !mounted) return;
    setState(() => _firstVirtualIndex = nextIndex);
  }

  int _logicalIndex(int virtualIndex) {
    final remainder = virtualIndex % widget.itemCount;
    return remainder < 0 ? remainder + widget.itemCount : remainder;
  }

  @override
  Widget build(BuildContext context) => Flow(
        // The public viewport owns clipping. Avoid a second clip layer here.
        clipBehavior: Clip.none,
        delegate: _DragGalleryFlowDelegate(
          position: widget.position,
          depth: widget.depth,
          repaint: widget.repaint,
          motionDirection: widget.motionDirection,
          motionSpeed: widget.motionSpeed,
          coastStartSpeed: widget.coastStartSpeed,
          coastStartStrength: widget.coastStartStrength,
          firstVirtualIndex: _firstVirtualIndex,
          itemExtent: widget.itemExtent,
          stride: widget.stride,
          minimumScale: widget.minimumScale,
        ),
        children: List.generate(widget.visibleItemCount, (slot) {
          final virtualIndex = _firstVirtualIndex + slot;
          return RepaintBoundary(
            key: ValueKey('drag_gallery_$virtualIndex'),
            child: widget.itemBuilder(
              context,
              _logicalIndex(virtualIndex),
            ),
          );
        }),
      );
}

class _DragGalleryFlowDelegate extends FlowDelegate {
  _DragGalleryFlowDelegate({
    required this.position,
    required this.depth,
    required Listenable repaint,
    required this.motionDirection,
    required this.motionSpeed,
    required this.coastStartSpeed,
    required this.coastStartStrength,
    required this.firstVirtualIndex,
    required this.itemExtent,
    required this.stride,
    required this.minimumScale,
  }) : super(repaint: repaint);

  final Animation<double> position;
  final Animation<double> depth;
  final double Function() motionDirection;
  final double Function() motionSpeed;
  final double Function() coastStartSpeed;
  final double Function() coastStartStrength;
  final int firstVirtualIndex;
  final double itemExtent;
  final double stride;
  final double minimumScale;

  double get _shift => position.value;

  @override
  BoxConstraints getConstraintsForChild(int index, BoxConstraints constraints) {
    return BoxConstraints.tightFor(
      width: itemExtent,
      height: constraints.maxHeight,
    );
  }

  @override
  void paintChildren(FlowPaintingContext context) {
    final viewportWidth = context.size.width;
    final viewportHeight = context.size.height;
    final inverseViewportWidth = viewportWidth == 0 ? 0.0 : 1 / viewportWidth;
    final direction = motionDirection();
    // Anime.js defaults to out(2). Use its mirrored in(2) while reversing so
    // both entering and leaving react immediately, then settle gently.
    final strength = depth.status == AnimationStatus.reverse
        ? _animeIn2(depth.value)
        : _animeOut2(depth.value);
    final shift = _shift;
    final speed = motionSpeed();
    final double speedStrength;
    if (position.isAnimating) {
      // During release momentum, reduce the deformation from the beginning of
      // the final slowdown rather than immediately on pointer release. Finish
      // while a small amount of physical movement still remains.
      final settledSpeed = stride * .25;
      final releaseSpeed = coastStartSpeed();
      final recoveryStartSpeed = math.max(
        settledSpeed * 1.5,
        math.min(releaseSpeed * .3, stride * 2.2),
      );
      final recoveryRange = recoveryStartSpeed - settledSpeed;
      if (recoveryRange <= 0) {
        speedStrength = 0;
      } else {
        final recoveryT =
            ((speed - settledSpeed) / recoveryRange).clamp(0.0, 1.0);
        speedStrength = coastStartStrength() * _animeIn2(recoveryT);
      }
    } else {
      // Direct manipulation stays responsive and reaches its full visual
      // strength without adding latency to the pointer position.
      final dragT = (speed / (stride * 11)).clamp(0.0, 1.0);
      speedStrength = _animeOut2(dragT);
    }
    final motionStrength = direction == 0 ? 0.0 : strength * speedStrength;
    final maximumLag = stride * .52 * motionStrength;
    final scaleRange = motionStrength * (1 - minimumScale);

    for (var slot = 0; slot < context.childCount; slot++) {
      final virtualIndex = firstVirtualIndex + slot;
      final left = virtualIndex * stride + shift;
      final centerX = left + itemExtent / 2;
      final positionT = viewportWidth == 0
          ? .5
          : (centerX * inverseViewportWidth).clamp(0.0, 1.0);
      // Cards closest to the movement front travel first. Cards behind them
      // progressively lag and shrink, producing the elastic "snake tail"
      // visible in the reference instead of scaling the whole track.
      final trailT = direction < 0 ? positionT : 1 - positionT;
      final curvedTrail = _animeIn2(trailT);
      final scale = 1 - scaleRange * curvedTrail;
      final lag =
          direction < 0 ? maximumLag * curvedTrail : -maximumLag * curvedTrail;

      final transform = Matrix4.identity()
        ..translateByDouble(
          left + lag + itemExtent / 2,
          viewportHeight / 2,
          0,
          1,
        )
        ..scaleByDouble(scale, scale, 1, 1)
        ..translateByDouble(
          -itemExtent / 2,
          -viewportHeight / 2,
          0,
          1,
        );
      context.paintChild(slot, transform: transform);
    }
  }

  @override
  bool shouldRepaint(covariant _DragGalleryFlowDelegate oldDelegate) {
    return oldDelegate.firstVirtualIndex != firstVirtualIndex ||
        oldDelegate.itemExtent != itemExtent ||
        oldDelegate.stride != stride ||
        oldDelegate.minimumScale != minimumScale ||
        oldDelegate.position != position ||
        oldDelegate.depth != depth;
  }
}
