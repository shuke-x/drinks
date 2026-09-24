import 'package:flutter/material.dart';

import '../../../components/glass.dart';
import '../../../components/cocktail_cover.dart';
import '../../../components/palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/cocktail.dart';

/// 瀑布流卡片 —— 原型规格：圆角 22 / 毛玻璃 blur(22) /
/// 封面 = 主题色渐变 + 中心 blur(14) 光球 64px + 右上 ABV 角标。
class WaterfallCard extends StatelessWidget {
  const WaterfallCard({
    super.key,
    required this.drink,
    required this.coverHeight,
    this.onTap,
  });

  final Cocktail drink;
  final double coverHeight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = drink.themeColor;
    final languageCode = Localizations.localeOf(context).languageCode;
    final primaryName = drink.nameFor(languageCode);
    final resolvedCoverHeight = coverHeight < 220 ? 220.0 : coverHeight;
    return RepaintBoundary(
      child: PressScale(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .4),
                blurRadius: 34,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(22),
              ),
              // 前景描边最后绘制，封面图片不会再压住卡片边缘。
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: .15)),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 封面
                    SizedBox(
                      height: resolvedCoverHeight,
                      width: double.infinity,
                      child: Stack(children: [
                        ClipRect(
                          child: CocktailCover(
                              drink: drink, fit: BoxFit.cover),
                        ),
                        if (drink.images.isEmpty)
                          Center(
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: drinkOrb(c),
                              ),
                            ),
                          ),
                        // 图片与下方文案之间用一层短渐变过渡，避免硬切。
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 72,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0),
                                    Colors.black.withValues(alpha: .18),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 9,
                          top: 9,
                          child: InfoPill(
                            label: '${drink.abv}%',
                            mono: true,
                            fontSize: 10,
                            fill: Colors.black.withValues(alpha: .32),
                            borderColor: Colors.white.withValues(alpha: .18),
                            textColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                          ),
                        ),
                      ]),
                    ),
                    // 文案
                    Padding(
                      padding: const EdgeInsets.fromLTRB(13, 12, 13, 14),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              primaryName,
                              style: languageCode == 'en'
                                  ? AppType.cocktailEnglish(
                                      size: 15, height: 1.2)
                                  : AppType.serifZh(size: 16, height: 1.25),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 5,
                              runSpacing: 5,
                              children: [
                                for (final tip in drink.cardTips)
                                  InfoPill(
                                    label: tip,
                                    fontSize: 10.5,
                                    fill: Colors.white.withValues(alpha: .1),
                                    borderColor:
                                        Colors.white.withValues(alpha: .15),
                                    textColor:
                                        Colors.white.withValues(alpha: .8),
                                  ),
                              ],
                            ),
                          ]),
                    ),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}
