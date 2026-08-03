import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../components/glass.dart';
import '../../../components/cocktail_cover.dart';
import '../../../components/palette.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/cocktail.dart';
import '../../../stores/deck_store.dart';
import '../../../l10n/l10n.dart';

/// 弧形卡片变换 —— 公式与原型完全一致：
///   x   = t * 296
///   arc = R - sqrt(R² - min(|x|,R)²)，R = 6000
///   deg = atan2(x, R)
///   opacity    = max(0, 1 - min(|t|,3) * 0.24)
///   brightness = 1 - min(|t|,3) * 0.1（用黑色蒙层近似）
///   视差：光球 -t*14，玻璃圆环 -t*24
class DeckCardTransform extends StatelessWidget {
  const DeckCardTransform({
    super.key,
    required this.drink,
    required this.t,
    required this.stageWidth,
    required this.landed,
    this.engaged = false,
    this.onTap,
  });

  final Cocktail drink;
  final double t;
  final double stageWidth;
  final bool landed;
  final bool engaged;
  final VoidCallback? onTap;

  // 增大横向比例，避免加高后变成过于狭长的“纸条”视觉。
  static const double cardW = 316;
  static const double cardH = 520;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final primaryName = drink.nameFor(languageCode);
    final alternateName = drink.alternateNameFor(languageCode);
    const r = kDeckArcRadius;
    final x = t * kDeckStep;
    final ax = math.min(x.abs(), r);
    final arc = r - math.sqrt(math.max(0, r * r - ax * ax));
    final rad = math.atan2(x, r);

    final at = t.abs();
    final clamped = math.min(at, 3.0);
    final dim = clamped * 0.1; // 1 - brightness
    final nearCenter = at < 0.5;

    final isCurrent = at < .5;
    return Positioned(
      left: stageWidth / 2 - cardW / 2,
      // 卡组整体较原设计下移 20px。
      top: 60,
      width: cardW,
      height: cardH,
      child: ExcludeSemantics(
        excluding: !isCurrent,
        child: Semantics(
          button: isCurrent,
          label: isCurrent
              ? '$primaryName, ${drink.base}, ${drink.abv}% ABV'
              : null,
          hint: isCurrent ? context.l10n.viewRecipe : null,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.translationValues(x, arc, 0)..rotateZ(rad),
            child: AnimatedScale(
              key: isCurrent ? const ValueKey('deck_card_motion') : null,
              scale: engaged ? .982 : 1,
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              child: GestureDetector(
                key: isCurrent ? const ValueKey('deck_card_current') : null,
                excludeFromSemantics: true,
                onTap: onTap,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      nearCenter
                          ? BoxShadow(
                              color: Colors.black.withOpacity(.55),
                              blurRadius: 54,
                              offset: const Offset(0, 26),
                            )
                          : BoxShadow(
                              color: Colors.black.withOpacity(.35),
                              blurRadius: 30,
                              offset: const Offset(0, 14),
                            ),
                      // 命中金色光晕（原型 haloPulse 外发光）
                      if (landed)
                        const BoxShadow(
                          color: Color(0x73C9A227),
                          blurRadius: 60,
                          spreadRadius: 12,
                        ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: RepaintBoundary(
                      child: Stack(fit: StackFit.expand, children: [
                        // 底：毛玻璃 + 主题色渐变
                        DecoratedBox(
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.07)),
                        ),
                        CocktailCover(drink: drink),
                        // 视差光球（34% 高度处，210px）
                        if (drink.images.isEmpty)
                          Positioned(
                            left: cardW / 2 - 105,
                            top: cardH * .34 - 105,
                            width: 210,
                            height: 210,
                            child: Opacity(
                              opacity: .85,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: drinkOrb(drink.themeColor),
                                ),
                              ),
                            ),
                          ),
                        // 玻璃圆环与默认光球成组展示。
                        if (drink.images.isEmpty)
                          Positioned(
                            left: cardW / 2 - 63,
                            top: cardH * .34 - 63,
                            width: 126,
                            height: 126,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white.withOpacity(.28)),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(.22),
                                    Colors.white.withOpacity(.04),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        // 底部渐隐 + 文案
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  const Color(0xFF08070B).withOpacity(.78),
                                  const Color(0xFF08070B).withOpacity(0),
                                ],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  primaryName,
                                  style: languageCode == 'en'
                                      ? AppType.cocktailEnglish(
                                          size: 29, height: 1.1)
                                      : AppType.serifZh(size: 27, height: 1.15),
                                ),
                                if (alternateName != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    alternateName,
                                    style: languageCode == 'en'
                                        ? AppType.serifZh(
                                            size: 13,
                                            weight: FontWeight.w500,
                                            color:
                                                Colors.white.withOpacity(.58),
                                          )
                                        : AppType.cocktailEnglish(
                                            size: 14,
                                            color:
                                                Colors.white.withOpacity(.62),
                                          ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Wrap(spacing: 6, runSpacing: 6, children: [
                                  for (final tip in drink.cardTips)
                                    InfoPill(label: tip),
                                  InfoPill(label: '${drink.abv}%', mono: true),
                                ]),
                              ],
                            ),
                          ),
                        ),
                        // 亮度衰减蒙层
                        if (dim > 0)
                          DecoratedBox(
                            decoration: BoxDecoration(
                                color: Colors.black.withOpacity(dim)),
                          ),
                        // 卡片描边 + 命中金色描边
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: landed
                                  ? AppColors.gold.withOpacity(.85)
                                  : Colors.white.withOpacity(.12),
                              width: landed ? 2 : 1,
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
