import 'dart:ui';

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
    return PressScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.4),
              blurRadius: 34,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 11, sigmaY: 11),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.08),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(.15)),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 封面
                    SizedBox(
                      height: coverHeight,
                      width: double.infinity,
                      child: Stack(children: [
                        CocktailCover(drink: drink),
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
                        Positioned(
                          right: 9,
                          top: 9,
                          child: InfoPill(
                            label: '${drink.abv}%',
                            mono: true,
                            fontSize: 10,
                            fill: Colors.black.withOpacity(.32),
                            borderColor: Colors.white.withOpacity(.18),
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
                            Text(drink.zh,
                                style: AppType.serifZh(size: 16, height: 1.25)),
                            const SizedBox(height: 3),
                            Text(drink.en,
                                style: AppType.playfair(
                                    size: 11.5,
                                    color: Colors.white.withOpacity(.5),
                                    height: 1.3)),
                            const SizedBox(height: 10),
                            InfoPill(
                              label: drink.base,
                              fontSize: 10.5,
                              fill: Colors.white.withOpacity(.1),
                              borderColor: Colors.white.withOpacity(.15),
                              textColor: Colors.white.withOpacity(.8),
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
