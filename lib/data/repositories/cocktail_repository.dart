import '../../models/cocktail.dart';
import '../../core/network/api_page.dart';
import '../datasources/cocktail_datasource.dart';
import '../datasources/cocktail_remote_datasource.dart';

/// 酒单仓库 —— 业务层唯一的数据入口，统一使用服务端数据源。
class CocktailRepository {
  CocktailRepository({CocktailDataSource? source})
      : _source = source ?? CocktailRemoteDataSource();

  final CocktailDataSource _source;

  Future<List<Cocktail>> getAll() => _source.getList();

  Future<List<Cocktail>> getBySpirit(String spirit) =>
      _source.getList(spirit: spirit);

  Future<ApiPage<Cocktail>> getPage({
    String? spirit,
    int page = 1,
    int limit = 20,
  }) =>
      _source.getPage(spirit: spirit, page: page, limit: limit);

  Future<Cocktail?> getDetail(String id) => _source.getDetail(id);

  Future<List<Cocktail>> getRecommendations() => _source.getRecommendations();
}
