import 'dart:math' as math;

import 'package:drinks/components/drag_parallax_carousel.dart';
import 'package:drinks/components/common/infinite_menu/infinite_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('drag carousel uses native page snapping', (tester) async {
    final controller = PageController(viewportFraction: .94);
    var selected = 0;
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 390,
            height: 240,
            child: DragParallaxCarousel(
              controller: controller,
              itemCount: 3,
              onPageChanged: (index) => selected = index,
              itemBuilder: (context, index) => ColoredBox(
                key: ValueKey('carousel_$index'),
                color: Colors.primaries[index],
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getCenter(find.byKey(const ValueKey('carousel_0'))).dx,
      closeTo(tester.getCenter(find.byType(DragParallaxCarousel)).dx, .01),
    );

    final carouselGesture = await tester.startGesture(
      tester.getCenter(find.byType(DragParallaxCarousel)),
    );
    await carouselGesture.moveBy(const Offset(-90, 0));
    await tester.pump();

    final movingCard = tester.widget<Transform>(
      find.byKey(const ValueKey('carousel_motion_0')),
    );
    expect(movingCard.transform.storage[2], greaterThan(.1));

    await carouselGesture.moveBy(const Offset(-240, 0));
    await carouselGesture.up();
    await tester.pumpAndSettle();

    expect(selected, 1);
    expect(find.byKey(const ValueKey('carousel_1')), findsOneWidget);
  });

  testWidgets('looping carousel advances continuously across its item boundary',
      (tester) async {
    final controller = PageController(initialPage: 12, viewportFraction: .94);
    var selected = 0;
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 390,
          height: 240,
          child: DragParallaxCarousel(
            controller: controller,
            itemCount: 3,
            loop: true,
            onPageChanged: (index) => selected = index,
            itemBuilder: (context, index) => ColoredBox(
              key: ValueKey('loop_carousel_$index'),
              color: Colors.primaries[index],
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('loop_carousel_0')), findsOneWidget);
    controller.jumpToPage(14);
    await tester.pump();
    expect(selected, 2);
    controller.jumpToPage(15);
    await tester.pump();
    expect(selected, 0);
    expect(find.byKey(const ValueKey('loop_carousel_0')), findsOneWidget);
  });

  testWidgets('infinite menu renders the 42-face spherical grid',
      (tester) async {
    InfiniteMenuItem? selected;
    final items = List.generate(
      20,
      (index) => InfiniteMenuItem(id: '$index', title: 'Drink $index'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 390,
          height: 430,
          child: InfiniteMenu(
            items: items,
            onSelected: (item) => selected = item,
          ),
        ),
      ),
    );

    final sphereFaces = find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          RegExp(r'^infinite_face_\d+$')
              .hasMatch((widget.key! as ValueKey<String>).value),
    );
    expect(sphereFaces, findsNWidgets(42));
    await tester.pump();
    expect(selected, isNotNull);

    final faceScales = find.byWidgetPredicate(
      (widget) =>
          widget is Transform &&
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith(
                'infinite_face_scale_',
              ),
    );
    expect(faceScales, findsNWidgets(42));
    final focusScales = find.byWidgetPredicate(
      (widget) =>
          widget is AnimatedScale &&
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith(
                'infinite_face_focus_',
              ),
    );
    expect(focusScales, findsNWidgets(42));
    final largestIdleFocus = focusScales
        .evaluate()
        .map((element) => (element.widget as AnimatedScale).scale)
        .reduce((a, b) => a > b ? a : b);
    expect(largestIdleFocus, 1.32);
    final idleStage = tester.widget<AnimatedScale>(
      find.byKey(const ValueKey('infinite_sphere_stage')),
    );
    expect(idleStage.scale, 2);
    expect(
      find.byKey(const ValueKey('infinite_menu_viewport')),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('infinite_menu_viewport'))),
      tester.getSize(find.byType(InfiniteMenu)),
    );
    expect(
      find.descendant(
        of: find.byType(InfiniteMenu),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
    final faceOpacities = find.byWidgetPredicate(
      (widget) =>
          widget is Opacity &&
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>)
              .value
              .startsWith('infinite_face_opacity_'),
    );
    expect(faceOpacities, findsNWidgets(42));
    expect(
      faceOpacities
          .evaluate()
          .where((element) => (element.widget as Opacity).opacity > 0)
          .length,
      5,
    );
    final materialFinder =
        find.byKey(const ValueKey('infinite_face_material_0'));
    final idleMaterial = tester.widget<ClipPath>(materialFinder);
    final idleMaterialLength = idleMaterial.clipper!
        .getClip(const Size(100, 100))
        .computeMetrics()
        .first
        .length;

    final focusedWidget = focusScales.evaluate().firstWhere(
          (element) => (element.widget as AnimatedScale).scale == 1.32,
        );
    final focusedKey =
        ((focusedWidget.widget.key! as ValueKey<String>).value).split('_').last;
    final focusedFaceFinder = find.byKey(ValueKey('infinite_face_$focusedKey'));
    final initialLeft = tester.widget<Positioned>(focusedFaceFinder).left!;
    final directionGesture = await tester.startGesture(
      tester.getCenter(find.byType(InfiniteMenu)),
    );
    await directionGesture.moveBy(const Offset(24, 0));
    await tester.pump();
    final firstRightLeft = tester.widget<Positioned>(focusedFaceFinder).left!;
    await directionGesture.moveBy(const Offset(24, 0));
    await tester.pump();
    final secondRightLeft = tester.widget<Positioned>(focusedFaceFinder).left!;
    expect(firstRightLeft, greaterThan(initialLeft));
    expect(secondRightLeft, greaterThan(firstRightLeft));
    await directionGesture.up();
    await tester.pumpAndSettle(const Duration(milliseconds: 16));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(InfiniteMenu)),
    );
    await gesture.moveBy(const Offset(72, -28));
    await tester.pump();

    final movingStage = tester.widget<AnimatedScale>(
      find.byKey(const ValueKey('infinite_sphere_stage')),
    );
    expect(movingStage.scale, 1);
    expect(
      faceOpacities
          .evaluate()
          .where((element) => (element.widget as Opacity).opacity > 0)
          .length,
      42,
    );
    final deformedFace = tester.widget<Transform>(
      find.byKey(const ValueKey('infinite_face_deformation_0')),
    );
    expect(deformedFace.transform.storage[0], greaterThan(1));
    final materialRotation = tester.widget<Transform>(
      find.byKey(const ValueKey('infinite_face_rotation_0')),
    );
    final contentRotation = tester.widget<Transform>(
      find.byKey(const ValueKey('infinite_face_content_rotation_0')),
    );
    final deformedContentTransform = Matrix4.copy(materialRotation.transform)
      ..multiply(deformedFace.transform)
      ..multiply(contentRotation.transform);
    final horizontalAxisLength = math.sqrt(
      deformedContentTransform.storage[0] *
              deformedContentTransform.storage[0] +
          deformedContentTransform.storage[1] *
              deformedContentTransform.storage[1],
    );
    final verticalAxisLength = math.sqrt(
      deformedContentTransform.storage[4] *
              deformedContentTransform.storage[4] +
          deformedContentTransform.storage[5] *
              deformedContentTransform.storage[5],
    );
    expect(
      math.max(horizontalAxisLength, verticalAxisLength),
      greaterThan(1),
    );
    final movingMaterial = tester.widget<ClipPath>(materialFinder);
    final movingMaterialLength = movingMaterial.clipper!
        .getClip(const Size(100, 100))
        .computeMetrics()
        .first
        .length;
    expect(
      (movingMaterialLength - idleMaterialLength).abs(),
      greaterThan(.1),
    );

    await gesture.up();
    await tester.pump();
    final releasedStage = tester.widget<AnimatedScale>(
      find.byKey(const ValueKey('infinite_sphere_stage')),
    );
    expect(releasedStage.scale, 2);
    await tester.pumpAndSettle(const Duration(milliseconds: 16));

    final settledStage = tester.widget<AnimatedScale>(
      find.byKey(const ValueKey('infinite_sphere_stage')),
    );
    expect(settledStage.scale, 2);
    expect(
      faceOpacities
          .evaluate()
          .where((element) => (element.widget as Opacity).opacity > 0)
          .length,
      5,
    );

    await tester.drag(find.byType(InfiniteMenu), const Offset(-120, 70));
    await tester.pumpAndSettle(const Duration(milliseconds: 16));

    final cancelledGesture = await tester.startGesture(
      tester.getCenter(find.byType(InfiniteMenu)),
    );
    await cancelledGesture.moveBy(const Offset(48, 24));
    await tester.pump();
    expect(
      tester
          .widget<AnimatedScale>(
            find.byKey(const ValueKey('infinite_sphere_stage')),
          )
          .scale,
      1,
    );
    await cancelledGesture.cancel();
    await tester.pump();
    expect(
      tester
          .widget<AnimatedScale>(
            find.byKey(const ValueKey('infinite_sphere_stage')),
          )
          .scale,
      2,
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 16));

    expect(sphereFaces, findsNWidgets(42));
    expect(selected, isNotNull);
  });
}
