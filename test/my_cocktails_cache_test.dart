import 'package:drinks/core/network/api_page.dart';
import 'package:drinks/core/query/query_cache.dart';
import 'package:drinks/data/apis/api_providers.dart';
import 'package:drinks/data/apis/user_api.dart';
import 'package:drinks/models/cocktail.dart';
import 'package:drinks/stores/my_cocktails_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('my cocktails reuses each status query until cacheTime expires',
      () async {
    final api = _CountingUserApi();
    final container = ProviderContainer(
      overrides: [
        userApiProvider.overrideWithValue(api),
        queryCachePolicyProvider.overrideWithValue(
          const QueryCachePolicy(cacheTime: Duration(milliseconds: 20)),
        ),
      ],
    );
    addTearDown(container.dispose);

    final first = container.listen(
      myCocktailsProvider(CocktailStatus.draft),
      (_, __) {},
      fireImmediately: true,
    );
    await Future<void>.delayed(Duration.zero);
    expect(first.read().items.single.id, 'draft-drink');
    expect(api.requestedStatuses, [CocktailStatus.draft]);

    first.close();
    final cached = container.listen(
      myCocktailsProvider(CocktailStatus.draft),
      (_, __) {},
      fireImmediately: true,
    );
    await Future<void>.delayed(Duration.zero);
    expect(cached.read().items.single.id, 'draft-drink');
    expect(api.requestedStatuses, [CocktailStatus.draft]);

    cached.close();
    await Future<void>.delayed(const Duration(milliseconds: 40));
    final expired = container.listen(
      myCocktailsProvider(CocktailStatus.draft),
      (_, __) {},
      fireImmediately: true,
    );
    await Future<void>.delayed(Duration.zero);

    expect(api.requestedStatuses, [CocktailStatus.draft, CocktailStatus.draft]);
    expired.close();
  });
}

class _CountingUserApi extends UserApi {
  final List<CocktailStatus?> requestedStatuses = [];

  @override
  Future<ApiPage<Cocktail>> myCocktailsPage({
    int page = 1,
    int limit = 20,
    CocktailStatus? status,
  }) async {
    requestedStatuses.add(status);
    return ApiPage(
      items: [_drink(status)],
      page: page,
      limit: limit,
      total: 1,
    );
  }
}

Cocktail _drink(CocktailStatus? status) => Cocktail(
      id: '${status?.name ?? 'all'}-drink',
      zh: '测试酒单',
      en: 'Test Drink',
      base: '金酒',
      abv: 20,
      color: '#0A84FF',
      tags: const [],
      glass: '',
      garnish: '',
      flavor: '',
      story: '',
      recipe: const [],
      steps: const [],
      status: status ?? CocktailStatus.draft,
    );
