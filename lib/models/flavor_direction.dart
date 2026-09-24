import 'package:flutter/material.dart';
import 'cocktail.dart';

class FlavorDirection {
  const FlavorDirection({
    required this.id,
    required this.zh,
    required this.en,
    required this.zhSubtitle,
    required this.enSubtitle,
    required this.keywords,
    required this.icon,
    required this.color,
    this.primaryWeight = 6,
    this.secondaryWeight = 2,
  });

  final String id;
  final String zh;
  final String en;
  final String zhSubtitle;
  final String enSubtitle;
  final List<String> keywords;
  final IconData icon;
  final Color color;
  final int primaryWeight;
  final int secondaryWeight;

  factory FlavorDirection.fromJson(Map<String, dynamic> json) =>
      FlavorDirection(
        id: json['id'] as String,
        zh: json['zh'] as String,
        en: json['en'] as String,
        zhSubtitle: json['zhSubtitle'] as String,
        enSubtitle: json['enSubtitle'] as String,
        keywords: (json['keywords'] as List).cast<String>(),
        color: Color(0xFF000000 |
            int.parse((json['color'] as String).substring(1), radix: 16)),
        icon: switch (json['icon']) {
          'sweet_sour' => Icons.water_drop_outlined,
          'fruit' => Icons.local_florist_outlined,
          'tea' => Icons.spa_outlined,
          'rich' => Icons.nightlight_outlined,
          _ => Icons.air_rounded,
        },
        primaryWeight: json['primaryWeight'] as int,
        secondaryWeight: json['secondaryWeight'] as int,
      );

  String nameFor(String language) => language == 'en' ? en : zh;
  String subtitleFor(String language) =>
      language == 'en' ? enSubtitle : zhSubtitle;
}

const flavorDirections = <FlavorDirection>[
  FlavorDirection(
    id: 'fresh',
    zh: '清爽解渴',
    en: 'Fresh & bright',
    zhSubtitle: '轻盈、明亮，适合慢慢喝',
    enSubtitle: 'Light, bright and easy to sip',
    keywords: ['fresh', 'citrus', '清爽', '柑橘', '苏打', '气泡'],
    icon: Icons.air_rounded,
    color: Color(0xFF64D2FF),
  ),
  FlavorDirection(
    id: 'sweet_sour',
    zh: '酸甜开胃',
    en: 'Sweet & sour',
    zhSubtitle: '酸度活泼，甜味恰到好处',
    enSubtitle: 'Lively acidity with a soft finish',
    keywords: ['sweet', 'sour', '酸甜', '酸', '柠檬', 'lime'],
    icon: Icons.water_drop_outlined,
    color: Color(0xFFFF9F0A),
  ),
  FlavorDirection(
    id: 'fruit',
    zh: '果香明显',
    en: 'Fruit forward',
    zhSubtitle: '饱满果味，第一口就很鲜明',
    enSubtitle: 'Juicy fruit that leads the first sip',
    keywords: ['fruit', 'fruity', '果香', 'berry', '莓', '桃', 'apple'],
    icon: Icons.local_florist_outlined,
    color: Color(0xFFFF6482),
  ),
  FlavorDirection(
    id: 'tea',
    zh: '茶香淡雅',
    en: 'Tea & herbal',
    zhSubtitle: '克制清雅，留一点草本余韵',
    enSubtitle: 'Quiet tea and herbal aromatics',
    keywords: ['tea', 'herbal', '茶香', '茶', '草本', '花香'],
    icon: Icons.spa_outlined,
    color: Color(0xFF30D158),
  ),
  FlavorDirection(
    id: 'rich',
    zh: '浓郁顺滑',
    en: 'Rich & smooth',
    zhSubtitle: '醇厚柔和，适合夜色渐深时',
    enSubtitle: 'Silky, deep and made for late hours',
    keywords: ['rich', 'smooth', '浓郁', '顺滑', '奶油', '咖啡', 'cream'],
    icon: Icons.nightlight_outlined,
    color: Color(0xFFBF5AF2),
  ),
];

FlavorDirection? flavorDirectionById(String id) {
  for (final flavor in flavorDirections) {
    if (flavor.id == id) return flavor;
  }
  return null;
}

List<Cocktail> rankDrinksForFlavor(
  List<Cocktail> drinks,
  FlavorDirection flavor,
) {
  final indexed = <({Cocktail drink, int index, int score})>[
    for (var index = 0; index < drinks.length; index++)
      (
        drink: drinks[index],
        index: index,
        score: _flavorScore(drinks[index], flavor),
      ),
  ];
  indexed.sort((a, b) {
    final scoreOrder = b.score.compareTo(a.score);
    return scoreOrder != 0 ? scoreOrder : a.index.compareTo(b.index);
  });
  return [for (final item in indexed) item.drink];
}

int _flavorScore(Cocktail drink, FlavorDirection flavor) {
  final primary = '${drink.flavor} ${drink.tags.join(' ')}'.toLowerCase();
  final secondary = '${drink.zh} ${drink.en} ${drink.base}'.toLowerCase();
  return flavor.keywords.fold<int>(0, (score, keyword) {
    final normalized = keyword.toLowerCase();
    if (primary.contains(normalized)) return score + flavor.primaryWeight;
    if (secondary.contains(normalized)) return score + flavor.secondaryWeight;
    return score;
  });
}
