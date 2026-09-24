import '../../core/network/dio_controller.dart';
import '../../core/network/api_page.dart';
import '../../models/cocktail.dart';

/// 鸡尾酒服务端接口，覆盖 `/cocktails` 的全部读写端点。
/// UI 应通过 Repository/Store 调用，不直接持有此类。
class CocktailApi {
  CocktailApi({DioController? controller, this.lang = 'zh'})
      : _controller = controller ?? DioController();

  final DioController _controller;
  final String lang;

  Future<List<CocktailCategory>> categories() => _controller.get(
        '/cocktail-categories',
        queryParameters: {'lang': lang},
        decoder: (data) => (data as List)
            .map((item) =>
                CocktailCategory.fromJson(item as Map<String, dynamic>))
            .toList(growable: false),
      );

  Future<ApiPage<Cocktail>> listPage({
    String? spirit,
    int page = 1,
    int limit = 20,
  }) =>
      _controller.getPage(
        '/cocktails',
        queryParameters: {
          'lang': lang,
          if (spirit != null) 'spirit': spirit,
          'page': page,
          'limit': limit,
        },
        decoder: _cocktailList,
      );

  Future<List<Cocktail>> list({
    String? spirit,
    int page = 1,
    int limit = 20,
  }) async =>
      (await listPage(spirit: spirit, page: page, limit: limit)).items;

  Future<List<Cocktail>> recommendations() => _controller.get(
        '/cocktails/recommendations',
        queryParameters: {'lang': lang},
        decoder: _cocktailList,
      );

  Future<List<Cocktail>> todayRecommendations() => _controller.get(
        '/cocktails/today-recommendations',
        queryParameters: {'lang': lang},
        decoder: (data) {
          final json = data as Map<String, dynamic>;
          return _cocktailList(json['items']);
        },
      );

  Future<Cocktail> random({String? spirit}) => _controller.get(
        '/cocktails/random',
        queryParameters: {
          'lang': lang,
          if (spirit != null) 'spirit': spirit,
        },
        decoder: _cocktail,
      );

  Future<Cocktail?> detail(String id) => _controller.get(
        '/cocktails/$id',
        queryParameters: {'lang': lang},
        decoder: (data) => data == null ? null : _cocktail(data),
      );

  Future<Cocktail> create(CocktailUpsertRequest request) => _controller.post(
        '/cocktails',
        data: request.toJson(),
        decoder: _cocktail,
      );

  /// 创建公开酒单并立即进入审核流程。
  ///
  /// 服务端创建接口始终先生成草稿，因此公开创建需要紧接着提交该草稿。
  Future<Cocktail> createForReview(CocktailUpsertRequest request) async {
    final created = await create(request);
    return submit(created.id);
  }

  Future<Cocktail> update(String id, CocktailUpsertRequest request) =>
      _controller.patch(
        '/cocktails/$id',
        data: request.toJson(),
        decoder: _mutationCocktail,
      );

  Future<Cocktail> submit(String id) => _controller.post(
        '/cocktails/$id/submit',
        decoder: _mutationCocktail,
      );

  Future<Cocktail> withdraw(String id) => _controller.post(
        '/cocktails/$id/withdraw',
        decoder: _mutationCocktail,
      );

  Future<String> delete(String id) => _controller.delete(
        '/cocktails/$id',
        decoder: (data) => (data as Map<String, dynamic>)['id'] as String,
      );

  static Cocktail _cocktail(dynamic data) =>
      Cocktail.fromJson(data as Map<String, dynamic>);

  static Cocktail _mutationCocktail(dynamic data) {
    final json = data as Map<String, dynamic>;
    if (json['cocktail'] is! Map<String, dynamic>) return _cocktail(json);
    final cocktail = _cocktail(json['cocktail']);
    final revision = json['revision'];
    return revision is Map<String, dynamic>
        ? cocktail.copyWith(latestRevision: CocktailRevision.fromJson(revision))
        : cocktail;
  }

  static List<Cocktail> _cocktailList(dynamic data) =>
      (data as List).map((item) => _cocktail(item)).toList(growable: false);
}

class CocktailCategory {
  const CocktailCategory({
    required this.id,
    required this.code,
    required this.name,
    this.nameEn,
  });

  final String id;
  final String code;
  final String name;
  final String? nameEn;

  factory CocktailCategory.fromJson(Map<String, dynamic> json) =>
      CocktailCategory(
        id: json['id'] as String,
        code: json['code'] as String,
        name: json['name'] as String,
        nameEn: json['nameEn'] as String?,
      );

  String labelFor(String languageCode) =>
      languageCode == 'en' && nameEn?.trim().isNotEmpty == true
          ? nameEn!
          : name;
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
    this.isPrivate,
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
  final bool? isPrivate;

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
        if (isPrivate != null) 'isPrivate': isPrivate,
      };
}
