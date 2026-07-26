import 'dart:ui';

/// 配方原料。
/// `ml` 与 `t` 二选一：`ml` 为数值用量（可做 ml/oz 换算），
/// `t` 为文本用量（如 "2 dash"、"10 片"），与设计稿数据结构一致。
class RecipeItem {
  final String n;
  final int? ml;
  final String? t;

  const RecipeItem({required this.n, this.ml, this.t});

  factory RecipeItem.fromJson(Map<String, dynamic> json) => RecipeItem(
        n: json['n'] as String,
        ml: json['ml'] as int?,
        t: json['t'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'n': n,
        if (ml != null) 'ml': ml,
        if (t != null) 't': t,
      };
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
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// 是否为用户上传的私人酒单，由服务端字段决定。
  bool get isMine => !isOfficial;

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
        createdAt: _date(json['createdAt']),
        updatedAt: _date(json['updatedAt']),
      );

  static DateTime? _date(dynamic value) =>
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
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
