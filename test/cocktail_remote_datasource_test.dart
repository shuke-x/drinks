import 'package:drinks/data/apis/cocktail_api.dart';
import 'package:drinks/data/datasources/cocktail_remote_datasource.dart';
import 'package:drinks/models/cocktail.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('home recommendations fall back when curated endpoint fails', () async {
    final source = CocktailRemoteDataSource(api: _FallbackCocktailApi());

    final result = await source.getRecommendations();

    expect(result.single.id, 'fallback');
  });
}

class _FallbackCocktailApi extends CocktailApi {
  @override
  Future<List<Cocktail>> todayRecommendations() async {
    throw StateError('endpoint unavailable');
  }

  @override
  Future<List<Cocktail>> recommendations() async => const [
        Cocktail(
          id: 'fallback',
          zh: '今日推荐',
          en: 'Featured',
          base: '金酒',
          abv: 20,
          color: '#0A84FF',
          tags: [],
          glass: '',
          garnish: '',
          flavor: '',
          story: '',
          recipe: [],
          steps: [],
          isOfficial: true,
        ),
      ];
}
