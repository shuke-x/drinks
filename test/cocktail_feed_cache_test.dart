import 'package:drinks/core/network/api_page.dart';
import 'package:drinks/core/query/query_cache.dart';
import 'package:drinks/data/datasources/cocktail_datasource.dart';
import 'package:drinks/data/repositories/cocktail_repository.dart';
import 'package:drinks/models/cocktail.dart';
import 'package:drinks/stores/cocktail_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('category feed is reused until its cache expires', () async {
    final source = _CountingCocktailDataSource();
    final container = ProviderContainer(
      overrides: [
        cocktailRepositoryProvider.overrideWithValue(
          CocktailRepository(source: source),
        ),
        queryCachePolicyProvider.overrideWithValue(
          const QueryCachePolicy(cacheTime: Duration(milliseconds: 20)),
        ),
      ],
    );
    addTearDown(container.dispose);

    final first = container.listen(
      cocktailFeedProvider('gin'),
      (_, __) {},
      fireImmediately: true,
    );
    await Future<void>.delayed(Duration.zero);

    expect(source.requestedSpirits, ['gin']);
    expect(first.read().items.single.id, 'gin-drink');

    first.close();
    final cached = container.listen(
      cocktailFeedProvider('gin'),
      (_, __) {},
      fireImmediately: true,
    );
    await Future<void>.delayed(Duration.zero);

    expect(source.requestedSpirits, ['gin']);
    expect(cached.read().items.single.id, 'gin-drink');

    cached.close();
    await Future<void>.delayed(const Duration(milliseconds: 40));

    final expired = container.listen(
      cocktailFeedProvider('gin'),
      (_, __) {},
      fireImmediately: true,
    );
    await Future<void>.delayed(Duration.zero);

    expect(source.requestedSpirits, ['gin', 'gin']);
    expect(expired.read().items.single.id, 'gin-drink');
    expired.close();
  });

  test('stale category keeps cached items while refetching on resume',
      () async {
    final source = _CountingCocktailDataSource();
    final container = ProviderContainer(
      overrides: [
        cocktailRepositoryProvider.overrideWithValue(
          CocktailRepository(source: source),
        ),
        queryCachePolicyProvider.overrideWithValue(
          const QueryCachePolicy(
            staleTime: Duration(milliseconds: 20),
            cacheTime: Duration(minutes: 1),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final first = container.listen(
      cocktailFeedProvider('rum'),
      (_, __) {},
      fireImmediately: true,
    );
    await Future<void>.delayed(Duration.zero);
    expect(first.read().items.single.id, 'rum-drink');
    first.close();

    await Future<void>.delayed(const Duration(milliseconds: 40));
    final stale = container.listen(
      cocktailFeedProvider('rum'),
      (_, __) {},
      fireImmediately: true,
    );

    expect(source.requestedSpirits, ['rum', 'rum']);
    expect(stale.read().items.single.id, 'rum-drink');
    expect(stale.read().isLoading, isTrue);

    await Future<void>.delayed(Duration.zero);
    expect(stale.read().isLoading, isFalse);
    stale.close();
  });
}

class _CountingCocktailDataSource implements CocktailDataSource {
  final List<String?> requestedSpirits = [];

  @override
  Future<ApiPage<Cocktail>> getPage({
    String? spirit,
    int page = 1,
    int limit = 20,
  }) async {
    requestedSpirits.add(spirit);
    return ApiPage(
      items: [_drink(spirit)],
      page: page,
      limit: limit,
      total: 1,
    );
  }

  @override
  Future<List<Cocktail>> getList({
    String? spirit,
    int page = 1,
    int limit = 50,
  }) async =>
      [_drink(spirit)];

  @override
  Future<Cocktail?> getDetail(String id) async => null;

  @override
  Future<List<Cocktail>> getRecommendations() async => const [];
}

Cocktail _drink(String? spirit) => Cocktail(
      id: '${spirit ?? 'all'}-drink',
      zh: '测试酒单',
      en: 'Test Drink',
      spirit: spirit,
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
    );
