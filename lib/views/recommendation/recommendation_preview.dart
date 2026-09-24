import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../components/ambient_background.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/cocktail.dart';
import 'recommendation_view.dart';

@Preview(
  name: '现在想喝什么 · iPhone',
  group: 'Recommendation',
  size: Size(390, 844),
  brightness: Brightness.dark,
)
Widget previewRecommendationPicker() => const _RecommendationPreview();

@Preview(
  name: '风味完整推荐 · iPhone',
  group: 'Recommendation',
  size: Size(390, 844),
  brightness: Brightness.dark,
)
Widget previewRecommendationResults() =>
    const _RecommendationPreview(initialFlavorId: 'fresh');

class _RecommendationPreview extends StatelessWidget {
  const _RecommendationPreview({this.initialFlavorId});

  final String? initialFlavorId;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Stack(
          fit: StackFit.expand,
          children: [
            const AmbientBackground(color: Color(0xFF6850C8)),
            if (initialFlavorId == null)
              RecommendationExperience(
                drinks: recommendationPreviewDrinks,
                onOpenDrink: (_) {},
              )
            else
              FlavorRecommendationPage(
                flavor: flavorDirectionById(initialFlavorId!)!,
                drinks: rankDrinksForFlavor(
                  recommendationPreviewDrinks,
                  flavorDirectionById(initialFlavorId!)!,
                ),
                onBack: () {},
                onOpenDrink: (_) {},
              ),
          ],
        ),
      );
}

const recommendationPreviewDrinks = <Cocktail>[
  Cocktail(
    id: 'preview-gin-fizz',
    zh: '青柠金菲士',
    en: 'Lime Gin Fizz',
    spirit: 'gin',
    base: '金酒',
    abv: 16,
    color: '#4FB3A6',
    tags: ['清爽', '柑橘', '气泡'],
    glass: 'Highball',
    garnish: '青柠皮',
    flavor: '青柠与苏打带来干净明亮的气泡感。',
    story: '',
    recipe: [],
    steps: [],
  ),
  Cocktail(
    id: 'preview-sour',
    zh: '金桂威士忌酸',
    en: 'Osmanthus Whiskey Sour',
    spirit: 'whiskey',
    base: '威士忌',
    abv: 21,
    color: '#D18B47',
    tags: ['酸甜', '花香', '柠檬'],
    glass: 'Coupe',
    garnish: '桂花',
    flavor: '柔和甜味包住鲜明酸度，尾段留有桂花香。',
    story: '',
    recipe: [],
    steps: [],
  ),
  Cocktail(
    id: 'preview-peach',
    zh: '白桃茉莉',
    en: 'White Peach Jasmine',
    spirit: 'vodka',
    base: '伏特加',
    abv: 14,
    color: '#E68AA3',
    tags: ['果香', '桃', '茶香'],
    glass: 'Collins',
    garnish: '白桃片',
    flavor: '成熟白桃的汁感与茉莉茶香轻轻叠在一起。',
    story: '',
    recipe: [],
    steps: [],
  ),
  Cocktail(
    id: 'preview-tea',
    zh: '乌龙月光',
    en: 'Oolong Moonlight',
    spirit: 'rum',
    base: '朗姆酒',
    abv: 18,
    color: '#7FA56A',
    tags: ['茶香', '草本', '清爽'],
    glass: 'Nick & Nora',
    garnish: '柠檬叶',
    flavor: '焙火乌龙安静展开，草本香气收住甜感。',
    story: '',
    recipe: [],
    steps: [],
  ),
  Cocktail(
    id: 'preview-rich',
    zh: '深夜丝绒',
    en: 'Midnight Velvet',
    spirit: 'whiskey',
    base: '波本威士忌',
    abv: 27,
    color: '#7550A8',
    tags: ['浓郁', '顺滑', '咖啡'],
    glass: 'Rocks',
    garnish: '可可碎',
    flavor: '咖啡与可可的浓郁香气，口感圆润顺滑。',
    story: '',
    recipe: [],
    steps: [],
  ),
  Cocktail(
    id: 'preview-berry',
    zh: '莓果暮色',
    en: 'Berry Dusk',
    spirit: 'gin',
    base: '金酒',
    abv: 17,
    color: '#A64D72',
    tags: ['berry', '果香', '酸甜'],
    glass: 'Coupe',
    garnish: '覆盆子',
    flavor: '莓果香气鲜明，酸甜之间有轻微杜松子气息。',
    story: '',
    recipe: [],
    steps: [],
  ),
];
