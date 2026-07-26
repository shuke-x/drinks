import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../components/glass.dart';
import '../../../components/cocktail_cover.dart';
import '../../../components/palette.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/cocktail.dart';

/// 今日推荐大卡片 —— 原型规格：高 238 / 圆角 28 / 毛玻璃 +
/// 主题色渐变铺底 + 右上角 blur(26) 光球，700ms 色彩过渡。
class FeaturedCard extends StatelessWidget {
  const FeaturedCard({super.key, required this.drink, this.onTap});

  final Cocktail drink;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = drink.themeColor;
    return PressScale(
      onTap: onTap,
      scale: .98,
      child: Container(
        height: 238,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.5),
              blurRadius: 60,
              offset: const Offset(0, 24),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 13, sigmaY: 13),
            child: Stack(fit: StackFit.expand, children: [
              // 主题色渐变（700ms 过渡）
              TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: c),
                duration: const Duration(milliseconds: 700),
                curve: AppMotion.standard,
                builder: (context, color, _) => DecoratedBox(
                  decoration: BoxDecoration(gradient: drinkGrad(color ?? c)),
                ),
              ),
              CocktailCover(drink: drink),
              // 右上光球
              if (drink.images.isEmpty)
                Positioned(
                  right: -30,
                  top: -24,
                  width: 190,
                  height: 190,
                  child: TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: c),
                    duration: const Duration(milliseconds: 700),
                    builder: (context, color, _) => Opacity(
                      opacity: .75,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: drinkOrb(color ?? c),
                        ),
                      ),
                    ),
                  ),
                ),
              // 描边
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withOpacity(.15)),
                ),
              ),
              // 内容
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      InfoPill(
                        label: '今日推荐',
                        fontSize: 11,
                        fill: Colors.white.withOpacity(.94),
                        borderColor: Colors.white.withOpacity(.94),
                        textColor: const Color(0xFF0D0B10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                      ),
                      const SizedBox(width: 8),
                      InfoPill(
                        label: '${drink.abv}% ABV',
                        mono: true,
                        fontSize: 11,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                      ),
                    ]),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(drink.en, style: AppType.playfair(size: 15)),
                        const SizedBox(height: 6),
                        Text(drink.zh,
                            style: AppType.serifZh(
                                size: 30, height: 1.1, letterSpacing: -.3)),
                        const SizedBox(height: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 262),
                          child: Text(
                            drink.flavor,
                            style: AppType.sans(
                                size: 13,
                                color: Colors.white.withOpacity(.62),
                                height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
