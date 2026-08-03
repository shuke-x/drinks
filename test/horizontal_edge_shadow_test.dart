import 'package:drinks/components/horizontal_edge_shadow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('horizontal edge lights follow the available scroll extent',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              height: 44,
              child: HorizontalEdgeShadow(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [SizedBox(width: 600, height: 44)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    AnimatedOpacity opacityFor(String key) => tester.widget<AnimatedOpacity>(
          find.descendant(
            of: find.byKey(ValueKey(key)),
            matching: find.byType(AnimatedOpacity),
          ),
        );

    expect(opacityFor('horizontal_edge_shadow_left').opacity, 0);
    expect(opacityFor('horizontal_edge_shadow_right').opacity, 1);

    await tester.drag(find.byType(ListView), const Offset(-100, 0));
    await tester.pump();

    expect(opacityFor('horizontal_edge_shadow_left').opacity, 1);
    expect(opacityFor('horizontal_edge_shadow_right').opacity, 1);
  });
}
