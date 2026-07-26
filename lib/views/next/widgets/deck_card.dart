import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../components/glass.dart';
import '../../../components/cocktail_cover.dart';
import '../../../components/palette.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/cocktail.dart';
import '../../../stores/deck_store.dart';

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
    this.onTap,
  });

  final Cocktail drink;
  final double t;
  final double stageWidth;
  final bool landed;
  final VoidCallback? onTap;

  // 增大横向比例，避免加高后变成过于狭长的“纸条”视觉。
  static const double cardW = 316;
  static const double cardH = 520;

  @override
  Widget build(BuildContext context) {
    const r = kDeckArcRadius;
    final x = t * kDeckStep;
    final ax = math.min(x.abs(), r);
    final arc = r - math.sqrt(math.max(0, r * r - ax * ax));
    final rad = math.atan2(x, r);

    final at = t.abs();
    final clamped = math.min(at, 3.0);
    final dim = clamped * 0.1; // 1 - brightness
    final nearCenter = at < 0.5;

    return Positioned(
      left: stageWidth / 2 - cardW / 2,
      // 卡组整体较原设计下移 20px。
      top: 60,
      width: cardW,
      height: cardH,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.translationValues(x, arc, 0)..rotateZ(rad),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                nearCenter
                    ? BoxShadow(
                        color: Colors.black.withOpacity(.55),
                        blurRadius: 90,
                        offset: const Offset(0, 34),
                      )
                    : BoxShadow(
                        color: Colors.black.withOpacity(.35),
                        blurRadius: 46,
                        offset: const Offset(0, 16),
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
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 13, sigmaY: 13),
                child: Stack(fit: StackFit.expand, children: [
                  // 底：毛玻璃 + 主题色渐变
                  DecoratedBox(
                    decoration:
                        BoxDecoration(color: Colors.white.withOpacity(.07)),
                  ),
                  CocktailCover(drink: drink),
                  // 视差光球（34% 高度处，210px）
                  if (drink.images.isEmpty)
                    Positioned(
                      left: cardW / 2 - 105 - t * 14,
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
                      left: cardW / 2 - 63 - t * 24,
                      top: cardH * .34 - 63,
                      width: 126,
                      height: 126,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white.withOpacity(.28)),
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
                          Text(drink.en, style: AppType.playfair(size: 14)),
                          const SizedBox(height: 6),
                          Text(drink.zh,
                              style: AppType.serifZh(size: 27, height: 1.15)),
                          const SizedBox(height: 12),
                          Wrap(spacing: 6, runSpacing: 6, children: [
                            InfoPill(label: drink.base),
                            InfoPill(label: '${drink.abv}%', mono: true),
                            if (drink.tags.isNotEmpty)
                              InfoPill(label: drink.tags.first),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  // 亮度衰减蒙层
                  if (dim > 0)
                    DecoratedBox(
                      decoration:
                          BoxDecoration(color: Colors.black.withOpacity(dim)),
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
    );
  }
}
