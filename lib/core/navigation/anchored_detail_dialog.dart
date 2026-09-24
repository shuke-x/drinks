import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A critically damped response, normalized to finish without an endpoint snap.
/// This is an app-tuned spring, not a reproduction of private UIKit constants.
class _ZoomSpring extends Curve {
  const _ZoomSpring();

  @override
  double transformInternal(double t) {
    const frequency = 5.8;
    double response(double x) =>
        1 - (1 + frequency * x) * math.exp(-frequency * x);
    return response(t) / response(1);
  }
}

/// The expanding surface owns one continuous clip. Image and detail content
/// scale uniformly inside it; only the mask changes aspect ratio. The image
/// arrives at the detail header instead of being cropped into a screen-sized
/// portrait and then replaced by a different composition.
Future<void> showAnchoredDetailDialog({
  required BuildContext context,
  required Rect sourceRect,
  required Widget preview,
  required WidgetBuilder builder,
  double destinationImageHeight = 330,
}) async {
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  final overlay = navigator.overlay!.context.findRenderObject()! as RenderBox;
  final origin = sourceRect.shift(-overlay.localToGlobal(Offset.zero));
  final route = RawDialogRoute<void>(
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: .42),
    transitionDuration:
        reduceMotion ? Duration.zero : const Duration(milliseconds: 320),
    pageBuilder: (context, _, __) => Builder(builder: builder),
    transitionBuilder: (context, animation, _, child) => LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final time = reduceMotion ? 1.0 : animation.value;
        final travel = const _ZoomSpring().transform(time);
        final reveal =
            const Interval(0, .32, curve: Curves.easeInOut).transform(time);
        final rect = Rect.lerp(origin, Offset.zero & size, travel)!;
        final scale = rect.width / size.width;
        // Keep rounded edges through the bulk of the flight and settle them
        // only as the surface meets the display, rather than squaring early.
        final cornerProgress =
            const Interval(.55, 1, curve: Curves.easeInOut).transform(travel);
        final radius = 16 * (1 - cornerProgress);
        return Stack(
          children: [
            Positioned.fromRect(
              rect: rect,
              child: ClipRSuperellipse(
                key: const ValueKey('anchored_detail_surface'),
                borderRadius: BorderRadius.circular(radius),
                clipBehavior: Clip.antiAlias,
                child: ColoredBox(
                  color: const Color(0xFF0D0B10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      IgnorePointer(
                        ignoring: time < .95,
                        child: ExcludeSemantics(
                          excluding: time < .95,
                          child: Opacity(
                            key: const ValueKey('anchored_detail_reveal'),
                            opacity: 1,
                            child: OverflowBox(
                              alignment: Alignment.topLeft,
                              minWidth: size.width,
                              maxWidth: size.width,
                              minHeight: size.height,
                              maxHeight: size.height,
                              child: Transform.scale(
                                key: const ValueKey('anchored_detail_scale'),
                                alignment: Alignment.topLeft,
                                scale: scale,
                                child:
                                    SizedBox.fromSize(size: size, child: child),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // The preview covers the initial image-sized clip. As the
                      // clip grows, the opaque detail below is already present;
                      // no empty backing surface is exposed.
                      ExcludeSemantics(
                        child: IgnorePointer(
                          child: Opacity(
                            key: const ValueKey('anchored_image_reveal'),
                            opacity: 1 - reveal,
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: SizedBox(
                                width: rect.width,
                                height: (origin.height / origin.width +
                                        (destinationImageHeight / size.width -
                                                origin.height / origin.width) *
                                            travel) *
                                    rect.width,
                                child: preview,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
  await navigator.push(route);
  // The source image must remain hidden until reverse animation is removed,
  // not merely until pop's result is returned at the start of dismissal.
  await route.completed;
}
