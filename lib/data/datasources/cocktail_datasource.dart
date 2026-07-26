import '../../models/cocktail.dart';

/// 酒单数据源抽象。
/// Mock（本地 assets）与 Remote（NestJS API）实现同一接口，
/// 由 [Env.dataSource] 决定注入哪个实现。
abstract class CocktailDataSource {
  /// 内置/官方酒单列表（可按基酒筛选，分页参数与后端契约一致）。
  Future<List<Cocktail>> getList(
      {String? spirit, int page = 1, int limit = 50});

  /// 详情。
  Future<Cocktail?> getDetail(String id);

  /// 今日推荐（Home 顶部轮播）。
  Future<List<Cocktail>> getRecommendations();
}
