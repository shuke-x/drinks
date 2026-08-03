import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widget_previews.dart';

@immutable
class InfiniteMenuItem {
  const InfiniteMenuItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.color = const Color(0xFF7C6B87),
  });

  /// 用于稳定识别菜单项的唯一标识。
  final String id;

  /// 菜单项的主标题。
  final String title;

  /// 可选的辅助说明文字。
  final String? subtitle;

  /// 可选的远程封面图片地址。
  final String? imageUrl;

  /// 没有图片时使用的项目主题色。
  final Color color;
}

typedef InfiniteMenuItemBuilder = Widget Function(
  BuildContext context,
  InfiniteMenuItem item,
  bool focused,
);

/// A Flutter interpretation of React Bits' WebGL Infinite Menu.
///
/// Forty-two circular faces sit on a subdivided icosahedron. A two-axis drag
/// rotates the sphere directly, and releasing immediately zooms and snaps the
/// closest face to the camera. The ticker sleeps while idle.
class InfiniteMenu extends StatefulWidget {
  const InfiniteMenu({
    super.key,
    required this.items,
    this.onSelected,
    this.onAction,
    this.itemBuilder,
    this.scale = 1,
  }) : assert(scale > 0);

  /// 显示在球形菜单中的数据项。
  final List<InfiniteMenuItem> items;

  /// 当前聚焦项发生变化时触发。
  final ValueChanged<InfiniteMenuItem>? onSelected;

  /// 用户点击当前项目的操作按钮时触发。
  final ValueChanged<InfiniteMenuItem>? onAction;

  /// 自定义每个菜单面的内容；为空时使用组件内置样式。
  final InfiniteMenuItemBuilder? itemBuilder;

  /// Base camera zoom while manipulating the sphere. At rest, the selected
  /// composition is presented at twice this zoom inside the module bounds.
  final double scale;

  @override
  State<InfiniteMenu> createState() => _InfiniteMenuState();
}

class _InfiniteMenuState extends State<InfiniteMenu>
    with SingleTickerProviderStateMixin {
  static final List<_Vec3> _spherePoints = _buildSpherePoints();

  late final Ticker _ticker;
  final ValueNotifier<int> _sphereFrame = ValueNotifier(0);
  late List<Widget> _defaultFaceChildren;
  Duration? _lastElapsed;
  _Quaternion _orientation = _Quaternion.identity;
  _Vec3 _motionAxis = const _Vec3(0, 1, 0);
  double _angularSpeed = 0;
  _Vec3? _lastArcballPoint;
  double _deformationStrength = 0;
  double _dragWidth = 1;
  double _dragHeight = 1;
  bool _dragging = false;
  bool _inertia = false;
  bool _snapping = false;
  int _activePoint = 0;

  InfiniteMenuItem get _activeItem =>
      widget.items[_activePoint % widget.items.length];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _rebuildDefaultFaceChildren();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.items.isNotEmpty) _snapImmediately(notify: true);
    });
  }

  @override
  void didUpdateWidget(covariant InfiniteMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.items, oldWidget.items) ||
        widget.itemBuilder != oldWidget.itemBuilder) {
      _rebuildDefaultFaceChildren();
    }
    if (widget.items.isEmpty) {
      _ticker.stop();
      _inertia = false;
      _snapping = false;
      _activePoint = 0;
    } else if (_activePoint >= _spherePoints.length) {
      _activePoint = 0;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _sphereFrame.dispose();
    super.dispose();
  }

  void _rebuildDefaultFaceChildren() {
    _defaultFaceChildren = widget.items.isEmpty
        ? const []
        : List<Widget>.generate(
            _spherePoints.length,
            (index) => _DefaultSphereFace(
              item: widget.items[index % widget.items.length],
            ),
            growable: false,
          );
  }

  void _markSphereNeedsPaint() {
    _sphereFrame.value++;
  }

  void _startTicker() {
    _lastElapsed = null;
    if (!_ticker.isActive) _ticker.start();
  }

  void _onTick(Duration elapsed) {
    final previous = _lastElapsed;
    _lastElapsed = elapsed;
    if (previous == null) return;
    final dt = ((elapsed - previous).inMicroseconds / 1000000).clamp(0.0, .032);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    if (_inertia) {
      _orientation = (_Quaternion.axisAngle(
                _motionAxis,
                _angularSpeed * dt,
              ) *
              _orientation)
          .normalized();
      _angularSpeed *= math.exp(-5.4 * dt);
      _settleDeformation(dt, reduceMotion: reduceMotion);
      if (_angularSpeed < .32) {
        _inertia = false;
        _activePoint = _nearestPoint();
        _snapping = true;
        // Reveal the new focus immediately; orientation correction continues
        // beneath the focused composition.
        setState(() {});
      }
      _markSphereNeedsPaint();
      return;
    }

    if (!_snapping) {
      _ticker.stop();
      return;
    }

    final point = _rotate(_spherePoints[_activePoint]);
    final correction = _Quaternion.between(
      point,
      const _Vec3(0, 0, 1),
    );
    final factor = 1 - math.exp(-11 * dt);
    _orientation = (_Quaternion.axisAngle(
              correction.axis,
              correction.angle * factor,
            ) *
            _orientation)
        .normalized();
    _settleDeformation(dt, reduceMotion: reduceMotion);
    if (correction.angle < .0015) {
      _finishMotion();
    } else {
      _markSphereNeedsPaint();
    }
  }

  void _beginSnap() {
    final nearest = _nearestPoint();
    _activePoint = nearest;
    _inertia = false;
    _snapping = true;
    _startTicker();
    // Start focus visibility and the 2× camera zoom in the same frame as the
    // snap. This avoids a settle-then-zoom sequence after releasing a drag.
    setState(() {});
  }

  void _finishMotion() {
    _ticker.stop();
    _inertia = false;
    _snapping = false;
    _lastElapsed = null;
    _angularSpeed = 0;
    _deformationStrength = 0;
    setState(() {});
    Feedback.forTap(context);
    widget.onSelected?.call(_activeItem);
  }

  void _snapImmediately({bool notify = false}) {
    if (widget.items.isEmpty) return;
    final nearest = _nearestPoint();
    _activePoint = nearest;
    final correction = _Quaternion.between(
      _rotate(_spherePoints[nearest]),
      const _Vec3(0, 0, 1),
    );
    _orientation = (correction * _orientation).normalized();
    _inertia = false;
    _snapping = false;
    _angularSpeed = 0;
    _deformationStrength = 0;
    setState(() {});
    if (notify) widget.onSelected?.call(_activeItem);
  }

  int _nearestPoint() {
    var nearest = 0;
    var nearestZ = -double.infinity;
    for (var index = 0; index < _spherePoints.length; index++) {
      final transformed = _rotate(_spherePoints[index]);
      if (transformed.z > nearestZ) {
        nearestZ = transformed.z;
        nearest = index;
      }
    }
    return nearest;
  }

  _Vec3 _rotate(_Vec3 point) => _orientation.rotate(point);

  _Vec3 _arcballPoint(Offset localPosition) {
    final diameter = math.max(1.0, math.min(_dragWidth, _dragHeight));
    var x = (localPosition.dx - _dragWidth / 2) * 2 / diameter;
    var y = (localPosition.dy - _dragHeight / 2) * 2 / diameter;
    final planarLengthSquared = x * x + y * y;
    if (planarLengthSquared > 1) {
      final inverseLength = 1 / math.sqrt(planarLengthSquared);
      x *= inverseLength;
      y *= inverseLength;
      return _Vec3(x, y, 0);
    }
    return _Vec3(x, y, math.sqrt(1 - planarLengthSquared));
  }

  void _onPanStart(DragStartDetails details) {
    _ticker.stop();
    _lastElapsed = null;
    _inertia = false;
    _snapping = false;
    _angularSpeed = 0;
    _lastArcballPoint = _arcballPoint(details.localPosition);
    setState(() => _dragging = true);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final current = _arcballPoint(details.localPosition);
    final previous = _lastArcballPoint ?? current;
    final delta = _Quaternion.between(previous, current);
    _orientation = (delta * _orientation).normalized();
    _lastArcballPoint = current;
    if (!reduceMotion && delta.angle > .0001) {
      _motionAxis = (_motionAxis * .28 + delta.axis * .72).normalized();
      final target = (delta.angle * 18).clamp(0.0, .68);
      _deformationStrength += (target - _deformationStrength) * .45;
    }
    _markSphereNeedsPaint();
  }

  void _onPanEnd(DragEndDetails details) =>
      _endInteraction(details.velocity.pixelsPerSecond);

  void _onPanCancel() => _endInteraction(Offset.zero);

  void _endInteraction(Offset velocity) {
    _dragging = false;
    _lastArcballPoint = null;
    if (MediaQuery.disableAnimationsOf(context)) {
      _snapImmediately(notify: true);
      return;
    }
    final diameter = math.max(1.0, math.min(_dragWidth, _dragHeight));
    _angularSpeed = (velocity.distance / diameter * 1.65).clamp(0.0, 5.5);
    if (_angularSpeed >= .35) {
      // Screen velocity maps to the same arcball axes used during direct
      // manipulation: rightward motion rotates around +Y, upward around +X.
      _motionAxis = _Vec3(-velocity.dy, velocity.dx, 0).normalized();
      _inertia = true;
      _snapping = false;
      _startTicker();
      setState(() {});
      return;
    }
    _beginSnap();
  }

  void _settleDeformation(double dt, {required bool reduceMotion}) {
    if (reduceMotion) {
      _deformationStrength = 0;
      return;
    }
    final factor = 1 - math.exp(-8.5 * dt);
    _deformationStrength += (0 - _deformationStrength) * factor;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    // Snapping is a focused presentation state: zoom and focus begin as soon
    // as the pointer is released, while orientation correction runs beneath.
    final manipulating = _dragging;
    final moving = _dragging || _inertia;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        _dragWidth = math.max(1, constraints.maxWidth);
        _dragHeight = math.max(1, constraints.maxHeight);
        return RepaintBoundary(
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                onPanCancel: _onPanCancel,
                onTap: widget.onAction == null
                    ? null
                    : () => widget.onAction?.call(_activeItem),
                child: ClipRect(
                  key: const ValueKey('infinite_menu_viewport'),
                  clipBehavior: Clip.hardEdge,
                  child: AnimatedScale(
                    key: const ValueKey('infinite_sphere_stage'),
                    scale: reduceMotion
                        ? widget.scale
                        : widget.scale * (manipulating ? 1 : 2),
                    duration: reduceMotion
                        ? Duration.zero
                        : Duration(milliseconds: manipulating ? 160 : 280),
                    curve: Curves.easeOutCubic,
                    child: SizedBox.expand(
                      child: AnimatedBuilder(
                        animation: _sphereFrame,
                        builder: (context, _) => _buildSphere(
                          context,
                          constraints,
                          moving: moving,
                          reduceMotion: reduceMotion,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: AnimatedOpacity(
                  opacity: moving ? 0 : 1,
                  duration: reduceMotion
                      ? Duration.zero
                      : Duration(milliseconds: moving ? 100 : 350),
                  curve: Curves.easeOutCubic,
                  child: _InformationOverlay(item: _activeItem),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedScale(
                  scale: moving ? 0 : 1,
                  duration: reduceMotion
                      ? Duration.zero
                      : Duration(milliseconds: moving ? 100 : 350),
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: moving ? 0 : 1,
                    duration: reduceMotion
                        ? Duration.zero
                        : Duration(milliseconds: moving ? 100 : 350),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _InfiniteMenuActionButton(
                        semanticLabel: _activeItem.title,
                        onTap: () => widget.onAction?.call(_activeItem),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSphere(
    BuildContext context,
    BoxConstraints constraints, {
    required bool moving,
    required bool reduceMotion,
  }) {
    final shortest = math.min(constraints.maxWidth, constraints.maxHeight);
    final radius = math.min(
      constraints.maxWidth * .54,
      constraints.maxHeight * .49,
    );
    final faceSize = (shortest * .17).clamp(48.0, 88.0);
    final transformed = <_ProjectedFace>[
      for (var index = 0; index < _spherePoints.length; index++)
        _ProjectedFace(index, _rotate(_spherePoints[index])),
    ]..sort((a, b) => a.point.z.compareTo(b.point.z));
    final idleVisibleFaces =
        moving ? null : _idleVisibleFaceIndices(transformed);

    return ClipRect(
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          for (final face in transformed)
            _buildFace(
              context,
              constraints,
              face,
              radius,
              faceSize,
              moving: moving,
              reduceMotion: reduceMotion,
              visible: idleVisibleFaces?.contains(face.index) ?? true,
            ),
        ],
      ),
    );
  }

  Set<int> _idleVisibleFaceIndices(List<_ProjectedFace> faces) {
    final visible = <int>{_activePoint};
    final quadrantFaces = List<_ProjectedFace?>.filled(4, null);
    for (final face in faces) {
      if (face.index == _activePoint) continue;
      final quadrant =
          (face.point.x >= 0 ? 1 : 0) + (face.point.y >= 0 ? 2 : 0);
      final current = quadrantFaces[quadrant];
      if (current == null || face.point.z > current.point.z) {
        quadrantFaces[quadrant] = face;
      }
    }
    for (final face in quadrantFaces) {
      if (face != null) visible.add(face.index);
    }
    return visible;
  }

  Widget _buildFace(
    BuildContext context,
    BoxConstraints constraints,
    _ProjectedFace face,
    double radius,
    double faceSize, {
    required bool moving,
    required bool reduceMotion,
    required bool visible,
  }) {
    final point = face.point;
    final perspective = 2.8 / (3.2 - point.z);
    final sphericalScale = .4 + .6 * point.z.abs();
    final focused = face.index == _activePoint && !moving;
    final scale = perspective * sphericalScale;
    final opacity =
        visible ? (.1 + .9 * ((point.z + 1) / 2)).clamp(.1, 1.0) : 0.0;
    final item = widget.items[face.index % widget.items.length];
    final customChild = widget.itemBuilder?.call(context, item, focused);
    // Reuse the exact child widget instance between ticker frames. This keeps
    // image resolution/loading and the static face subtree out of the hot
    // animation build path.
    final child = customChild ?? _defaultFaceChildren[face.index];
    // React Bits uses cross(centerPosition, rotationAxis) in the disc vertex
    // shader. This is the screen-space direction in which the moving disc
    // trails along the sphere tangent.
    final tangentVelocity = point.cross(_motionAxis);
    final tangentLength = math.sqrt(
      tangentVelocity.x * tangentVelocity.x +
          tangentVelocity.y * tangentVelocity.y,
    );
    final deformation = reduceMotion || tangentLength < .0001
        ? Offset.zero
        : Offset(
              tangentVelocity.x / tangentLength,
              tangentVelocity.y / tangentLength,
            ) *
            _deformationStrength;

    return Positioned(
      key: ValueKey('infinite_face_${face.index}'),
      left: constraints.maxWidth / 2 +
          point.x * radius * perspective -
          faceSize / 2,
      top: constraints.maxHeight / 2 +
          point.y * radius * perspective -
          faceSize / 2,
      width: faceSize,
      height: faceSize,
      child: Transform.scale(
        key: ValueKey('infinite_face_scale_${face.index}'),
        scale: scale,
        child: AnimatedScale(
          key: ValueKey('infinite_face_focus_${face.index}'),
          scale: focused ? 1.32 : 1,
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 360),
          curve: focused ? Curves.easeOutBack : Curves.easeOutCubic,
          child: Opacity(
            key: ValueKey('infinite_face_opacity_${face.index}'),
            opacity: opacity,
            child: _InertialDisc(
              faceIndex: face.index,
              deformation: deformation,
              child: RepaintBoundary(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// CPU counterpart of the source demo's 56-segment disc vertex shader.
///
/// Boundary vertices move along each disc's sphere tangent using:
/// `sign(x) * (1 - pow(1 - abs(x), 3))`. Unlike an affine oval scale, this
/// keeps the shoulders soft and makes the moving material visibly irregular.
class _InertialDisc extends StatelessWidget {
  const _InertialDisc({
    required this.faceIndex,
    required this.deformation,
    required this.child,
  });

  final int faceIndex;
  final Offset deformation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final amount = deformation.distance.clamp(0.0, .68);
    final angle =
        amount < .001 ? 0.0 : math.atan2(deformation.dy, deformation.dx);
    final clipper = _InertialMaterialClipper(amount);
    return Transform.rotate(
      key: ValueKey('infinite_face_rotation_$faceIndex'),
      angle: angle,
      child: Transform(
        key: ValueKey('infinite_face_deformation_$faceIndex'),
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          1 + amount,
          1,
          1,
        ),
        child: ClipPath(
          key: ValueKey('infinite_face_material_$faceIndex'),
          clipper: clipper,
          clipBehavior: Clip.antiAlias,
          // Keep the texture's upright orientation while allowing it to
          // stretch with the irregular outline. The source WebGL version
          // deforms the textured mesh itself; counter-scaling it into a
          // circle would instead create an unrelated colored halo.
          child: Transform.rotate(
            key: ValueKey('infinite_face_content_rotation_$faceIndex'),
            angle: -angle,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _InertialMaterialClipper extends CustomClipper<Path> {
  _InertialMaterialClipper(this.amount);

  static const _segments = 56;
  static final List<double> _directions = List<double>.generate(
    _segments,
    (index) => math.cos(index / _segments * math.pi * 2),
    growable: false,
  );
  static final List<double> _verticals = List<double>.generate(
    _segments,
    (index) => math.sin(index / _segments * math.pi * 2),
    growable: false,
  );
  static final List<double> _weights = _directions
      .map((direction) => 1 - math.pow(1 - direction.abs(), 3).toDouble())
      .toList(growable: false);
  final double amount;
  Size? _cachedSize;
  Path? _cachedPath;

  @override
  Path getClip(Size size) {
    if (_cachedSize == size && _cachedPath != null) return _cachedPath!;
    final center = Offset(size.width / 2, size.height / 2);
    final radiusX = size.width / 2;
    final radiusY = size.height / 2;
    final horizontalNormalization = 1 + amount;
    final path = Path();

    for (var index = 0; index < _segments; index++) {
      final direction = _directions[index];
      final displacement = amount * direction.sign * _weights[index];
      final normalizedX = (direction + displacement) / horizontalNormalization;
      final point = Offset(
        center.dx + normalizedX * radiusX,
        center.dy + _verticals[index] * radiusY,
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    _cachedSize = size;
    _cachedPath = path;
    return path;
  }

  @override
  bool shouldReclip(covariant _InertialMaterialClipper oldClipper) =>
      (amount - oldClipper.amount).abs() > .001;
}

class _InfiniteMenuActionButton extends StatelessWidget {
  const _InfiniteMenuActionButton({
    required this.semanticLabel,
    required this.onTap,
  });

  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: onTap,
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: .10),
            border: Border.all(
              color: Colors.white.withValues(alpha: .18),
            ),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.north_east_rounded,
            size: 22,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _InformationOverlay extends StatelessWidget {
  const _InformationOverlay({required this.item});

  final InfiniteMenuItem item;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 132),
                child: Text(
                  item.title,
                  style: DefaultTextStyle.of(context).style.copyWith(
                        fontSize: 29,
                        fontWeight: FontWeight.w700,
                        height: 1.02,
                        color: Colors.white,
                      ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 92),
                child: Text(
                  item.subtitle ?? '',
                  textAlign: TextAlign.left,
                  style: DefaultTextStyle.of(context).style.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                        color: Colors.white.withValues(alpha: .72),
                      ),
                ),
              ),
            ),
          ),
        ],
      );
}

class _DefaultSphereFace extends StatelessWidget {
  const _DefaultSphereFace({required this.item});

  final InfiniteMenuItem item;

  @override
  Widget build(BuildContext context) {
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            item.color,
            Color.lerp(item.color, Colors.black, .48)!,
          ],
        ),
      ),
      child: Center(
        child: Text(
          item.title.isEmpty ? '•' : item.title.characters.first,
          style: DefaultTextStyle.of(context).style.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: .84),
              ),
        ),
      ),
    );
    return item.imageUrl == null
        ? fallback
        : Image.network(
            item.imageUrl!,
            fit: BoxFit.cover,
            cacheWidth: 256,
            filterQuality: FilterQuality.low,
            gaplessPlayback: true,
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : fallback,
            errorBuilder: (_, __, ___) => fallback,
          );
  }
}

class _Vec3 {
  const _Vec3(this.x, this.y, this.z);

  static const zero = _Vec3(0, 0, 0);

  final double x;
  final double y;
  final double z;

  double get length => math.sqrt(x * x + y * y + z * z);

  _Vec3 normalized() {
    final magnitude = length;
    if (magnitude < .0000001) return zero;
    return this / magnitude;
  }

  double dot(_Vec3 other) => x * other.x + y * other.y + z * other.z;

  _Vec3 cross(_Vec3 other) => _Vec3(
        y * other.z - z * other.y,
        z * other.x - x * other.z,
        x * other.y - y * other.x,
      );

  _Vec3 operator +(_Vec3 other) => _Vec3(x + other.x, y + other.y, z + other.z);

  _Vec3 operator -(_Vec3 other) => _Vec3(x - other.x, y - other.y, z - other.z);

  _Vec3 operator *(double scale) => _Vec3(x * scale, y * scale, z * scale);

  _Vec3 operator /(double scale) => _Vec3(x / scale, y / scale, z / scale);
}

class _Quaternion {
  const _Quaternion(this.x, this.y, this.z, this.w);

  static const identity = _Quaternion(0, 0, 0, 1);

  final double x;
  final double y;
  final double z;
  final double w;

  factory _Quaternion.axisAngle(_Vec3 rawAxis, double angle) {
    if (angle.abs() < .0000001 || rawAxis.length < .0000001) return identity;
    final axis = rawAxis.normalized();
    final half = angle / 2;
    final sine = math.sin(half);
    return _Quaternion(
      axis.x * sine,
      axis.y * sine,
      axis.z * sine,
      math.cos(half),
    );
  }

  factory _Quaternion.between(_Vec3 from, _Vec3 to) {
    final first = from.normalized();
    final second = to.normalized();
    final cosine = first.dot(second).clamp(-1.0, 1.0);
    if (cosine > .999999) return identity;
    if (cosine < -.999999) {
      final helper =
          first.x.abs() < .8 ? const _Vec3(1, 0, 0) : const _Vec3(0, 1, 0);
      return _Quaternion.axisAngle(first.cross(helper), math.pi);
    }
    final cross = first.cross(second);
    return _Quaternion(cross.x, cross.y, cross.z, 1 + cosine).normalized();
  }

  double get angle {
    final normalizedW = normalized().w.clamp(-1.0, 1.0);
    return 2 * math.acos(normalizedW).clamp(0.0, math.pi);
  }

  _Vec3 get axis {
    final value = normalized();
    final sine = math.sqrt(math.max(0, 1 - value.w * value.w));
    return sine < .000001
        ? const _Vec3(0, 1, 0)
        : _Vec3(value.x / sine, value.y / sine, value.z / sine);
  }

  _Quaternion normalized() {
    final magnitude = math.sqrt(x * x + y * y + z * z + w * w);
    if (magnitude < .0000001) return identity;
    return _Quaternion(
        x / magnitude, y / magnitude, z / magnitude, w / magnitude);
  }

  _Quaternion operator *(_Quaternion other) => _Quaternion(
        w * other.x + x * other.w + y * other.z - z * other.y,
        w * other.y - x * other.z + y * other.w + z * other.x,
        w * other.z + x * other.y - y * other.x + z * other.w,
        w * other.w - x * other.x - y * other.y - z * other.z,
      );

  _Vec3 rotate(_Vec3 point) {
    final vector = _Vec3(x, y, z);
    final twiceCross = vector.cross(point) * 2;
    return point + twiceCross * w + vector.cross(twiceCross);
  }
}

class _ProjectedFace {
  const _ProjectedFace(this.index, this.point);

  final int index;
  final _Vec3 point;
}

List<_Vec3> _buildSpherePoints() {
  final golden = (1 + math.sqrt(5)) / 2;
  final vertices = <_Vec3>[
    _Vec3(-1, golden, 0),
    _Vec3(1, golden, 0),
    _Vec3(-1, -golden, 0),
    _Vec3(1, -golden, 0),
    _Vec3(0, -1, golden),
    _Vec3(0, 1, golden),
    _Vec3(0, -1, -golden),
    _Vec3(0, 1, -golden),
    _Vec3(golden, 0, -1),
    _Vec3(golden, 0, 1),
    _Vec3(-golden, 0, -1),
    _Vec3(-golden, 0, 1),
  ];
  const faces = <List<int>>[
    [0, 11, 5],
    [0, 5, 1],
    [0, 1, 7],
    [0, 7, 10],
    [0, 10, 11],
    [1, 5, 9],
    [5, 11, 4],
    [11, 10, 2],
    [10, 7, 6],
    [7, 1, 8],
    [3, 9, 4],
    [3, 4, 2],
    [3, 2, 6],
    [3, 6, 8],
    [3, 8, 9],
    [4, 9, 5],
    [2, 4, 11],
    [6, 2, 10],
    [8, 6, 7],
    [9, 8, 1],
  ];
  final midpointCache = <String, int>{};

  int midpoint(int a, int b) {
    final low = math.min(a, b);
    final high = math.max(a, b);
    final key = '$low:$high';
    final cached = midpointCache[key];
    if (cached != null) return cached;
    final first = vertices[a];
    final second = vertices[b];
    final index = vertices.length;
    vertices.add(
      _Vec3(
        (first.x + second.x) / 2,
        (first.y + second.y) / 2,
        (first.z + second.z) / 2,
      ),
    );
    midpointCache[key] = index;
    return index;
  }

  for (final face in faces) {
    midpoint(face[0], face[1]);
    midpoint(face[1], face[2]);
    midpoint(face[2], face[0]);
  }
  return List.unmodifiable(vertices.map((point) => point.normalized()));
}

@Preview(
  name: 'Infinite sphere menu',
  size: Size(390, 520),
  brightness: Brightness.dark,
)
Widget previewInfiniteMenu() => const Material(
      color: Color(0xFF100E13),
      child: InfiniteMenu(
        items: [
          InfiniteMenuItem(
            id: 'one',
            title: 'Velvet Night',
            subtitle: 'Floral\nDry',
            color: Color(0xFF8A5578),
          ),
          InfiniteMenuItem(
            id: 'two',
            title: 'Midnight Sour',
            subtitle: 'Citrus\nBright',
            color: Color(0xFF7866B4),
          ),
          InfiniteMenuItem(
            id: 'three',
            title: 'Quiet Smoke',
            subtitle: 'Smoky\nRich',
            color: Color(0xFF76665B),
          ),
          InfiniteMenuItem(
            id: 'four',
            title: 'Afterglow',
            subtitle: 'Fruity\nSoft',
            color: Color(0xFFB36A68),
          ),
          InfiniteMenuItem(
            id: 'five',
            title: 'Moon Garden',
            subtitle: 'Herbal\nClean',
            color: Color(0xFF577A6D),
          ),
        ],
      ),
    );
