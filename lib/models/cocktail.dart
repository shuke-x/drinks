import 'dart:ui';

/// 配方原料。
/// `ml` 与 `t` 二选一：`ml` 为数值用量（可做 ml/oz 换算），
/// `t` 为文本用量（如 "2 dash"、"10 片"），与设计稿数据结构一致。
class RecipeItem {
  final String n;
  final num? ml;
  final String? t;

  const RecipeItem({required this.n, this.ml, this.t});

  factory RecipeItem.fromJson(Map<String, dynamic> json) => RecipeItem(
        n: json['n'] as String,
        ml: json['ml'] as num?,
        t: json['t'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'n': n,
        if (ml != null) 'ml': ml,
        if (t != null) 't': t,
      };
}

class CocktailPublisher {
  const CocktailPublisher({
    this.id,
    required this.name,
    this.avatarUrl,
    this.deleted = false,
  });

  final String? id;
  final String name;
  final String? avatarUrl;
  final bool deleted;

  factory CocktailPublisher.fromJson(Map<String, dynamic> json) =>
      CocktailPublisher(
        id: json['id'] as String?,
        name: json['name'] as String? ?? '该账户已注销',
        avatarUrl: json['avatarUrl'] as String?,
        deleted: json['deleted'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatarUrl': avatarUrl,
        'deleted': deleted,
      };
}

enum CocktailStatus {
  draft,
  pending,
  rejected,
  published,
  offline;

  static CocktailStatus fromJson(dynamic value) {
    return CocktailStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => CocktailStatus.published,
    );
  }
}

class CocktailRevision {
  const CocktailRevision({
    required this.id,
    required this.status,
    this.content = const {},
    this.rejectReason,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final CocktailStatus status;
  final Map<String, dynamic> content;
  final String? rejectReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CocktailRevision.fromJson(Map<String, dynamic> json) =>
      CocktailRevision(
        id: json['id'] as String,
        status: CocktailStatus.fromJson(json['status']),
        content: json['content'] is Map
            ? Map<String, dynamic>.from(json['content'] as Map)
            : const {},
        rejectReason: json['rejectReason'] as String?,
        createdAt: Cocktail.parseDate(json['createdAt']),
        updatedAt: Cocktail.parseDate(json['updatedAt']),
      );
}

/// 鸡尾酒模型 —— 与服务端 `API.md` 中的酒单对象保持一致。
class Cocktail {
  final String id;
  final String zh;
  final String en;

  /// 服务端筛选标识，如 gin / whiskey；展示时使用 [base] 中文名。
  final String? spirit;
  final String base;
  final int abv;

  /// 主题色（十六进制字符串，如 "#4FB3A6"），驱动氛围背景与卡片渐变。
  final String color;
  final List<String> images;
  final List<String> tags;
  final String glass;
  final String garnish;
  final String flavor;
  final String story;
  final List<RecipeItem> recipe;
  final List<String> steps;
  final bool isOfficial;
  final bool isPrivate;
  final CocktailStatus status;
  final CocktailPublisher? publisher;
  final CocktailRevision? latestRevision;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? rejectReason;
  final DateTime? publishedAt;
  final String? offlineReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool isOwnedBy(String? userId) => userId != null && publisher?.id == userId;

  /// 可用于展示的首张封面。空数组或空字符串时交由客户端主题色样式兜底。
  String? get coverImageUrl {
    for (final image in images) {
      final value = image.trim();
      if (value.isEmpty) continue;
      return value;
    }
    return null;
  }

  bool get hasCoverImage => coverImageUrl != null;

  /// 当前语言下用于卡片和详情页的主标题。
  ///
  /// Excel 导入的旧数据可能没有英文名；这种情况下回退到中文，避免英文界面
  /// 出现空标题。英文名存在时，英文界面绝不再把中文名当作主标题。
  String nameFor(String languageCode) {
    final english = en.trim();
    final chinese = zh.trim();
    if (languageCode == 'en') {
      return english.isNotEmpty ? english : chinese;
    }
    return chinese.isNotEmpty ? chinese : english;
  }

  /// 仅在确实有另一种语言名称时返回副标题，避免中英文重复或空白占位。
  String? alternateNameFor(String languageCode) {
    final primary = nameFor(languageCode);
    final alternate = (languageCode == 'en' ? zh : en).trim();
    if (alternate.isEmpty || alternate.toLowerCase() == primary.toLowerCase()) {
      return null;
    }
    return alternate;
  }

  /// 酒单卡片使用 1–3 个简短、去重的描述标签。
  List<String> get cardTips {
    final values = <String>[base, ...tags];
    final result = <String>[];
    for (final raw in values) {
      final value = raw.trim();
      if (value.isEmpty ||
          result.any((item) => item.toLowerCase() == value.toLowerCase())) {
        continue;
      }
      result.add(value);
      if (result.length == 3) break;
    }
    return result;
  }

  const Cocktail({
    required this.id,
    required this.zh,
    required this.en,
    this.spirit,
    required this.base,
    required this.abv,
    required this.color,
    this.images = const [],
    required this.tags,
    required this.glass,
    required this.garnish,
    required this.flavor,
    required this.story,
    required this.recipe,
    required this.steps,
    this.isOfficial = false,
    this.isPrivate = false,
    this.status = CocktailStatus.published,
    this.publisher,
    this.latestRevision,
    this.submittedAt,
    this.reviewedAt,
    this.rejectReason,
    this.publishedAt,
    this.offlineReason,
    this.createdAt,
    this.updatedAt,
  });

  Color get themeColor {
    final hex = color.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  factory Cocktail.fromJson(Map<String, dynamic> json) => Cocktail(
        id: json['id'] as String,
        zh: json['zh'] as String,
        en: json['en'] as String? ?? '',
        spirit: json['spirit'] as String?,
        base: json['base'] as String,
        abv: (json['abv'] as num?)?.toInt() ?? 20,
        color: json['color'] as String? ?? '#0A84FF',
        images: (json['images'] as List?)?.cast<String>() ?? const [],
        tags: (json['tags'] as List?)?.cast<String>() ?? const [],
        glass: json['glass'] as String? ?? '',
        garnish: json['garnish'] as String? ?? '',
        flavor: json['flavor'] as String? ?? '',
        story: json['story'] as String? ?? '',
        recipe: (json['recipe'] as List? ?? const [])
            .map((e) => RecipeItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        steps: (json['steps'] as List?)?.cast<String>() ?? const [],
        isOfficial: json['isOfficial'] as bool? ?? false,
        isPrivate: json['isPrivate'] as bool? ?? false,
        status: CocktailStatus.fromJson(json['status']),
        publisher: json['publisher'] is Map<String, dynamic>
            ? CocktailPublisher.fromJson(
                json['publisher'] as Map<String, dynamic>)
            : null,
        latestRevision: json['latestRevision'] is Map<String, dynamic>
            ? CocktailRevision.fromJson(
                json['latestRevision'] as Map<String, dynamic>)
            : null,
        submittedAt: parseDate(json['submittedAt']),
        reviewedAt: parseDate(json['reviewedAt']),
        rejectReason: json['rejectReason'] as String?,
        publishedAt: parseDate(json['publishedAt']),
        offlineReason: json['offlineReason'] as String?,
        createdAt: parseDate(json['createdAt']),
        updatedAt: parseDate(json['updatedAt']),
      );

  static DateTime? parseDate(dynamic value) =>
      value is String ? DateTime.tryParse(value) : null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'zh': zh,
        'en': en,
        if (spirit != null) 'spirit': spirit,
        'base': base,
        'abv': abv,
        'color': color,
        'images': images,
        'tags': tags,
        'glass': glass,
        'garnish': garnish,
        'flavor': flavor,
        'story': story,
        'recipe': recipe.map((e) => e.toJson()).toList(),
        'steps': steps,
        'isOfficial': isOfficial,
        'isPrivate': isPrivate,
        'status': status.name,
        if (publisher != null) 'publisher': publisher!.toJson(),
        if (submittedAt != null) 'submittedAt': submittedAt!.toIso8601String(),
        if (reviewedAt != null) 'reviewedAt': reviewedAt!.toIso8601String(),
        if (rejectReason != null) 'rejectReason': rejectReason,
        if (publishedAt != null) 'publishedAt': publishedAt!.toIso8601String(),
        if (offlineReason != null) 'offlineReason': offlineReason,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  Cocktail copyWith({
    String? id,
    String? zh,
    String? en,
    String? spirit,
    String? base,
    int? abv,
    String? color,
    List<String>? images,
    List<String>? tags,
    String? glass,
    String? garnish,
    String? flavor,
    String? story,
    List<RecipeItem>? recipe,
    List<String>? steps,
    bool? isOfficial,
    bool? isPrivate,
    CocktailStatus? status,
    CocktailPublisher? publisher,
    CocktailRevision? latestRevision,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? rejectReason,
    DateTime? publishedAt,
    String? offlineReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Cocktail(
        id: id ?? this.id,
        zh: zh ?? this.zh,
        en: en ?? this.en,
        spirit: spirit ?? this.spirit,
        base: base ?? this.base,
        abv: abv ?? this.abv,
        color: color ?? this.color,
        images: images ?? this.images,
        tags: tags ?? this.tags,
        glass: glass ?? this.glass,
        garnish: garnish ?? this.garnish,
        flavor: flavor ?? this.flavor,
        story: story ?? this.story,
        recipe: recipe ?? this.recipe,
        steps: steps ?? this.steps,
        isOfficial: isOfficial ?? this.isOfficial,
        isPrivate: isPrivate ?? this.isPrivate,
        status: status ?? this.status,
        publisher: publisher ?? this.publisher,
        latestRevision: latestRevision ?? this.latestRevision,
        submittedAt: submittedAt ?? this.submittedAt,
        reviewedAt: reviewedAt ?? this.reviewedAt,
        rejectReason: rejectReason ?? this.rejectReason,
        publishedAt: publishedAt ?? this.publishedAt,
        offlineReason: offlineReason ?? this.offlineReason,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
