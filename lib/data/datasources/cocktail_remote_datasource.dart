import '../../models/cocktail.dart';
import '../../core/network/api_page.dart';
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
  Future<ApiPage<Cocktail>> getPage({
    String? spirit,
    int page = 1,
    int limit = 20,
  }) =>
      _api.listPage(spirit: spirit, page: page, limit: limit);

  @override
  Future<Cocktail?> getDetail(String id) => _api.detail(id);

  @override
  Future<List<Cocktail>> getRecommendations() async {
    try {
      final curated = await _api.todayRecommendations();
      if (curated.isNotEmpty) return curated;
    } catch (_) {
      // Keep the existing Home banner available while an older backend is
      // deployed or the curated daily endpoint is temporarily unavailable.
    }
    return _api.recommendations();
  }
}
