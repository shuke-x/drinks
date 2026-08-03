import 'package:drinks/app.dart';
import 'package:drinks/core/network/api_page.dart';
import 'package:drinks/data/apis/api_providers.dart';
import 'package:drinks/data/apis/cocktail_api.dart';
import 'package:drinks/data/repositories/cocktail_repository.dart';
import 'package:drinks/models/cocktail.dart';
import 'package:drinks/stores/cocktail_store.dart';
import 'package:drinks/views/detail/detail_view.dart';
import 'package:drinks/views/next/next_view.dart';
import 'package:drinks/views/user/auth_gate_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tabs, deck detail, and create flow remain interactive',
      (tester) async {
    SharedPreferences.setMockInitialValues(const {});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cocktailRepositoryProvider.overrideWithValue(_FakeRepository()),
          cocktailApiProvider.overrideWithValue(_FakeCocktailApi()),
        ],
        child: const TonightDrinksApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    final tabRects = List.generate(
      4,
      (index) => tester.getRect(find.byKey(ValueKey('tab_$index'))),
    );
    for (final rect in tabRects) {
      expect(rect.height, 56);
      expect(rect.width, closeTo(tabRects.first.width, .01));
    }
    for (var index = 1; index < tabRects.length; index++) {
      expect(tabRects[index].left, closeTo(tabRects[index - 1].right, .01));
    }

    await tester.tap(find.byKey(const ValueKey('tab_1')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(NextView), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('deck_card_current')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(DetailView), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('detail_back')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(NextView), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('create_cocktail')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(AuthGateView), findsOneWidget);
  });
}

class _FakeRepository extends CocktailRepository {
  _FakeRepository();

  static const drinks = [
    Cocktail(
      id: 'old-fashioned',
      zh: '古典',
      en: 'Old Fashioned',
      spirit: 'whiskey',
      base: '威士忌',
      abv: 32,
      color: '#B06C35',
      tags: ['烈酒感'],
      glass: '古典杯',
      garnish: '橙皮',
      flavor: '醇厚',
      story: '经典威士忌酒单。',
      recipe: [RecipeItem(n: '威士忌', ml: 45)],
      steps: ['搅拌后倒入杯中'],
      isOfficial: true,
    ),
  ];

  @override
  Future<List<Cocktail>> getAll() async => drinks;

  @override
  Future<List<Cocktail>> getRecommendations() async => drinks;

  @override
  Future<List<Cocktail>> getBySpirit(String spirit) async => drinks;

  @override
  Future<ApiPage<Cocktail>> getPage({
    String? spirit,
    int page = 1,
    int limit = 20,
  }) async =>
      const ApiPage(items: drinks, page: 1, limit: 20, total: 1);

  @override
  Future<Cocktail?> getDetail(String id) async => drinks.first;
}

class _FakeCocktailApi extends CocktailApi {
  @override
  Future<List<CocktailCategory>> categories() async => const [
        CocktailCategory(
          id: 'whiskey',
          code: 'whiskey',
          name: '威士忌',
          nameEn: 'Whiskey',
        ),
      ];
}
