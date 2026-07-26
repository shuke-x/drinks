import '../../core/network/dio_controller.dart';
import '../../models/cocktail.dart';

/// 鸡尾酒服务端接口，覆盖 `/cocktails` 的全部读写端点。
/// UI 应通过 Repository/Store 调用，不直接持有此类。
class CocktailApi {
  CocktailApi({DioController? controller})
      : _controller = controller ?? DioController();

  final DioController _controller;

  Future<List<Cocktail>> list({String? spirit, int page = 1, int limit = 20}) =>
      _controller.get(
        '/cocktails',
        queryParameters: {
          if (spirit != null && spirit != '全部') 'spirit': spirit,
          'page': page,
          'limit': limit,
        },
        decoder: _cocktailList,
      );

  Future<List<Cocktail>> recommendations() => _controller.get(
        '/cocktails/recommendations',
        decoder: _cocktailList,
      );

  Future<Cocktail> random({String? spirit}) => _controller.get(
        '/cocktails/random',
        queryParameters: {
          if (spirit != null && spirit != '全部') 'spirit': spirit,
        },
        decoder: _cocktail,
      );

  Future<Cocktail?> detail(String id) => _controller.get(
        '/cocktails/$id',
        decoder: (data) => data == null ? null : _cocktail(data),
      );

  Future<Cocktail> create(CocktailUpsertRequest request) => _controller.post(
        '/cocktails',
        data: request.toJson(),
        decoder: _cocktail,
      );

  Future<Cocktail> update(String id, CocktailUpsertRequest request) =>
      _controller.patch(
        '/cocktails/$id',
        data: request.toJson(),
        decoder: _cocktail,
      );

  Future<String> delete(String id) => _controller.delete(
        '/cocktails/$id',
        decoder: (data) => (data as Map<String, dynamic>)['id'] as String,
      );

  static Cocktail _cocktail(dynamic data) =>
      Cocktail.fromJson(data as Map<String, dynamic>);

  static List<Cocktail> _cocktailList(dynamic data) =>
      (data as List).map((item) => _cocktail(item)).toList(growable: false);
}

/// 创建/修改私人酒单的请求体。未设置字段不会写入 PATCH 请求。
class CocktailUpsertRequest {
  const CocktailUpsertRequest({
    this.zh,
    this.en,
    this.spirit,
    this.base,
    this.abv,
    this.color,
    this.tags,
    this.images,
    this.glass,
    this.garnish,
    this.flavor,
    this.story,
    this.recipe,
    this.steps,
  });

  final String? zh;
  final String? en;
  final String? spirit;
  final String? base;
  final int? abv;
  final String? color;
  final List<String>? tags;
  final List<String>? images;
  final String? glass;
  final String? garnish;
  final String? flavor;
  final String? story;
  final List<RecipeItem>? recipe;
  final List<String>? steps;

  Map<String, dynamic> toJson() => {
        if (zh != null) 'zh': zh,
        if (en != null) 'en': en,
        if (spirit != null) 'spirit': spirit,
        if (base != null) 'base': base,
        if (abv != null) 'abv': abv,
        if (color != null) 'color': color,
        if (tags != null) 'tags': tags,
        if (images != null) 'images': images,
        if (glass != null) 'glass': glass,
        if (garnish != null) 'garnish': garnish,
        if (flavor != null) 'flavor': flavor,
        if (story != null) 'story': story,
        if (recipe != null)
          'recipe': recipe!.map((item) => item.toJson()).toList(),
        if (steps != null) 'steps': steps,
      };
}
