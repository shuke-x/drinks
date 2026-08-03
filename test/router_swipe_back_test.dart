import 'dart:async';

import 'package:drinks/core/theme/app_theme.dart';
import 'package:drinks/components/frosted_page_overlay.dart';
import 'package:drinks/components/common/common.dart';
import 'package:drinks/data/apis/api_providers.dart';
import 'package:drinks/l10n/generated/app_localizations.dart';
import 'package:drinks/router/app_router.dart';
import 'package:drinks/stores/cocktail_store.dart';
import 'package:drinks/views/system/system_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('secondary routes support interactive iOS edge swipe back',
      (tester) async {
    appRouter.go('/home');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recommendationsProvider.overrideWith((ref) async => const []),
          builtinDrinksProvider.overrideWith((ref) async => const []),
          homeDrinksProvider(null).overrideWith((ref) async => const []),
          cocktailCategoriesProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp.router(
          theme: AppTheme.dark(),
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: appRouter,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(GlassTabBar), findsOneWidget);
    final initialTabBarElement = tester.element(find.byType(GlassTabBar));

    unawaited(appRouter.push<void>('/settings'));
    await tester.pump();
    expect(find.byType(GlassTabBar), findsNothing);
    await tester.pump(const Duration(milliseconds: 600));

    final route = ModalRoute.of(tester.element(find.byType(SystemView)))!;
    expect(route, isA<PageRoute<void>>());
    expect((route as PageRoute<void>).popGestureEnabled, isTrue);
    expect(route.opaque, isTrue);
    final secondaryBackground = tester.widget<ColoredBox>(
      find.byKey(const ValueKey('secondary_page_background')),
    );
    expect(secondaryBackground.color.a, 1.0);
    final frostedOverlay = find.byType(FrostedPageOverlay);
    expect(
      find.descendant(
        of: frostedOverlay,
        matching: find.byKey(const ValueKey('frosted_page_backdrop')),
      ),
      findsNothing,
      reason: 'secondary routes must not blur the primary page on entry',
    );

    final screenSize = tester.getSize(find.byType(SystemView));
    final gesture = await tester.startGesture(
      Offset(2, tester.getCenter(find.byType(SystemView)).dy),
    );
    await gesture.moveBy(Offset(screenSize.width * .8, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(
      find.descendant(
        of: frostedOverlay,
        matching: find.byKey(const ValueKey('frosted_page_backdrop')),
      ),
      findsNothing,
      reason: 'secondary routes must remain blur-free while dismissing',
    );
    expect(
      find.byType(GlassTabBar),
      findsOneWidget,
      reason: 'the retained tab bar should return as soon as pop is accepted',
    );
    await tester.pumpAndSettle();

    expect(find.byType(SystemView), findsNothing);
    expect(appRouter.routeInformationProvider.value.uri.path, '/home');
    expect(find.byType(GlassTabBar), findsOneWidget);
    expect(
      identical(tester.element(find.byType(GlassTabBar)), initialTabBarElement),
      isTrue,
      reason: 'returning to a primary route must reuse the mounted tab bar',
    );
  });
}
