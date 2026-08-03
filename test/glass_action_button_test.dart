import 'package:drinks/components/common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('GlassActionButton accepts an external width', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassActionButton(
              key: const ValueKey('sized_glass_action'),
              label: 'Design yours',
              width: 224,
              height: 52,
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    final button = find.byKey(const ValueKey('sized_glass_action'));
    expect(tester.getSize(button), const Size(224, 52));

    await tester.tap(button);
    expect(tapped, isTrue);
  });

  testWidgets('GlassActionButton can place its icon after the label',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassActionButton(
              key: ValueKey('right_icon_action'),
              label: 'Continue',
              icon: Icons.arrow_forward,
              iconPlace: GlassActionIconPlace.right,
            ),
          ),
        ),
      ),
    );

    final button = find.byKey(const ValueKey('right_icon_action'));
    final icon = find.descendant(
      of: button,
      matching: find.byKey(const ValueKey('glass_action_icon')),
    );
    final label = find.descendant(
      of: button,
      matching: find.byKey(const ValueKey('glass_action_label')),
    );

    expect(tester.getCenter(icon).dx, greaterThan(tester.getCenter(label).dx));
  });

  testWidgets('GlassCircleButton keeps a 44pt minimum hit region',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassCircleButton(
              key: ValueKey('small_circle_action'),
              icon: Icons.add,
              size: 38,
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('small_circle_action'))),
      const Size.square(44),
    );
  });
}
