import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Flutter counterpart of React Bits' perspective Carousel drag treatment.
///
/// The track follows the finger through [PageView], while every card rotates
/// from +90° through 0° to -90° around its Y axis. Release uses the same
/// stiffness/damping pair as the Motion spring in the reference component.
class DragParallaxCarousel extends StatelessWidget {
  const DragParallaxCarousel({
    super.key,
    required this.controller,
    required this.itemCount,
    required this.itemBuilder,
    this.onPageChanged,
    this.onInteractionStart,
    this.onInteractionEnd,
    this.loop = false,
    this.perspective = 1000,
  }) : assert(!loop || itemCount > 0);

  final PageController controller;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ValueChanged<int>? onPageChanged;
  final VoidCallback? onInteractionStart;
  final VoidCallback? onInteractionEnd;
  final bool loop;
  final double perspective;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification &&
            notification.dragDetails != null) {
          onInteractionStart?.call();
        } else if (notification is ScrollEndNotification) {
          onInteractionEnd?.call();
        }
        return false;
      },
      child: PageView.builder(
        controller: controller,
        padEnds: true,
        allowImplicitScrolling: false,
        physics: const _ReactBitsPagePhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: loop ? null : itemCount,
        onPageChanged: (index) =>
            onPageChanged?.call(loop ? index % itemCount : index),
        itemBuilder: (context, index) {
          final logicalIndex = loop ? index % itemCount : index;
          return AnimatedBuilder(
            animation: controller,
            child: RepaintBoundary(
              child: itemBuilder(context, logicalIndex),
            ),
            builder: (context, child) {
              if (reduceMotion || !controller.hasClients) return child!;
              final page = controller.position.haveDimensions
                  ? (controller.page ?? controller.initialPage.toDouble())
                  : controller.initialPage.toDouble();
              final delta = index - page;
              // Flutter's Y rotation sign is opposite to the CSS perspective
              // direction used by the reference. This sign folds cards inward.
              final angle = delta * (3.141592653589793 / 2);
              return Transform(
                key: ValueKey('carousel_motion_$index'),
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 1 / perspective)
                  ..rotateY(angle),
                child: child,
              );
            },
          );
        },
      ),
    );
  }
}

class _ReactBitsPagePhysics extends PageScrollPhysics {
  const _ReactBitsPagePhysics({super.parent});

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 1,
        stiffness: 300,
        damping: 30,
      );

  @override
  _ReactBitsPagePhysics applyTo(ScrollPhysics? ancestor) =>
      _ReactBitsPagePhysics(parent: buildParent(ancestor));
}

@Preview(
  name: 'Drag parallax carousel',
  size: Size(390, 280),
  brightness: Brightness.dark,
)
Widget previewDragParallaxCarousel() => const _CarouselPreview();

class _CarouselPreview extends StatefulWidget {
  const _CarouselPreview();

  @override
  State<_CarouselPreview> createState() => _CarouselPreviewState();
}

class _CarouselPreviewState extends State<_CarouselPreview> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: .9);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFF100E13),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: DragParallaxCarousel(
            controller: _controller,
            itemCount: 3,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFB8A1FF).withValues(alpha: .8),
                      const Color(0xFF4A314F).withValues(alpha: .9),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    '0${index + 1}',
                    style: const TextStyle(fontSize: 34),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
