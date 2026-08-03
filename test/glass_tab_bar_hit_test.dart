import 'package:drinks/components/common/common.dart';
import 'package:drinks/l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tab items split the full bar into four equal hit regions',
      (tester) async {
    var selected = -1;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: GlassTabBar(
              current: 0,
              width: 320,
              height: 60,
              onSelect: (index) => selected = index,
            ),
          ),
        ),
      ),
    );

    final rects = List.generate(
      4,
      (index) => tester.getRect(find.byKey(ValueKey('tab_$index'))),
    );
    for (final rect in rects) {
      expect(rect.size, const Size(80, 60));
    }
    for (var index = 1; index < rects.length; index++) {
      expect(rects[index].left, rects[index - 1].right);
    }

    await tester.tapAt(Offset(rects.first.center.dx, rects.first.top + 1));
    expect(selected, 0);
    await tester.tapAt(Offset(rects.last.center.dx, rects.last.bottom - 1));
    expect(selected, 3);
  });

  testWidgets('iOS without native capability uses the Flutter fallback',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: GlassTabBar(current: 0, onSelect: (_) {}),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('tab_0')), findsOneWidget);
    expect(find.byType(UiKitView), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
}
