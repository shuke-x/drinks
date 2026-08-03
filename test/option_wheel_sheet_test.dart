import 'package:drinks/components/option_wheel_sheet.dart';
import 'package:drinks/core/theme/app_typography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('brand text styles disable fallback underline decorations', () {
    final styles = [
      AppType.title(),
      AppType.tips(),
      AppType.serifZh(),
      AppType.playfair(),
      AppType.cocktailEnglish(),
      AppType.sans(),
      AppType.mono(),
      AppType.eyebrow(),
    ];
    for (final style in styles) {
      expect(style.decoration, TextDecoration.none);
      expect(style.decorationColor, Colors.transparent);
    }
  });

  testWidgets('option button uses exactly half of its available width',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OptionWheelButton(
                    controlKey: const ValueKey('option_button'),
                    label: 'Gin',
                    semanticLabel: 'Base spirit',
                    onPressed: () => tapped = true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('option_button'))),
      const Size(180, 44),
    );
    expect(
      tester
          .widget<Icon>(
            find.byKey(const ValueKey('option_wheel_disclosure_icon')),
          )
          .icon,
      CupertinoIcons.arrow_down,
    );
    await tester.tap(find.byKey(const ValueKey('option_button')));
    expect(tapped, isTrue);
  });

  testWidgets('option button opens a white-action Cupertino wheel',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _WheelHost()));

    await tester.tap(find.byKey(const ValueKey('wheel_trigger')));
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoPicker), findsOneWidget);
    final popupSurface = tester.widget<CupertinoPopupSurface>(
      find.byType(CupertinoPopupSurface),
    );
    expect(popupSurface.blurSigma, 0);
    expect(popupSurface.isSurfacePainted, isFalse);
    final surface = tester.widget<ColoredBox>(
      find.byKey(const ValueKey('option_wheel_opaque_surface')),
    );
    expect(surface.color.a, 1);
    final cancelText = tester.widget<Text>(find.text('Cancel'));
    final doneText = tester.widget<Text>(find.text('Done'));
    expect(cancelText.style?.color, Colors.white);
    expect(doneText.style?.color, Colors.white);
    expect(cancelText.style?.decoration, TextDecoration.none);
    expect(doneText.style?.decoration, TextDecoration.none);

    await tester.drag(find.byType(CupertinoPicker), const Offset(0, -44));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Two'), findsOneWidget);
  });
}

class _WheelHost extends StatefulWidget {
  const _WheelHost();

  @override
  State<_WheelHost> createState() => _WheelHostState();
}

class _WheelHostState extends State<_WheelHost> {
  String _selected = 'one';

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: SizedBox(
            width: 320,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OptionWheelButton(
                  controlKey: const ValueKey('wheel_trigger'),
                  label: _selected == 'one' ? 'One' : 'Two',
                  semanticLabel: 'Option',
                  onPressed: () async {
                    final value = await showOptionWheel<String>(
                      context: context,
                      title: 'Option',
                      cancelLabel: 'Cancel',
                      doneLabel: 'Done',
                      selectedValue: _selected,
                      options: const [
                        OptionWheelItem(value: 'one', label: 'One'),
                        OptionWheelItem(value: 'two', label: 'Two'),
                      ],
                    );
                    if (value != null && mounted) {
                      setState(() => _selected = value);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      );
}
