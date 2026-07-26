import '../../models/cocktail.dart';
import '../apis/cocktail_api.dart';
import 'cocktail_datasource.dart';

/// Remote 数据源：将 Repository 的数据源契约适配到服务端 [CocktailApi]。
class CocktailRemoteDataSource implements CocktailDataSource {
  CocktailRemoteDataSource({CocktailApi? api}) : _api = api ?? CocktailApi();

  final CocktailApi _api;

  @override
  Future<List<Cocktail>> getList({
    String? spirit,
    int page = 1,
    int limit = 50,
  }) =>
      _api.list(spirit: spirit, page: page, limit: limit);

  @override
  Future<Cocktail?> getDetail(String id) => _api.detail(id);

  @override
  Future<List<Cocktail>> getRecommendations() => _api.recommendations();
}
