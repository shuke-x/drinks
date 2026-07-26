import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/cocktail.dart';
import 'palette.dart';

/// 酒单卡片统一封面。
///
/// 服务端的 [Cocktail.images] 第一张有效完整 URL 优先展示；没有图片、空字符串
/// 或加载失败时回退到主题色渐变。
class CocktailCover extends StatelessWidget {
  const CocktailCover(
      {super.key, required this.drink, this.fit = BoxFit.cover});

  final Cocktail drink;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final fallback = DecoratedBox(
      decoration: BoxDecoration(gradient: drinkGrad(drink.themeColor)),
      child: const SizedBox.expand(),
    );
    final source = drink.coverImageUrl;
    if (source == null) return fallback;

    final isSvg = Uri.parse(source).path.toLowerCase().endsWith('.svg');
    final image = isSvg
        ? SvgPicture.network(
            source,
            fit: fit,
            placeholderBuilder: (_) => fallback,
          )
        : Image.network(
            source,
            fit: fit,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) => fallback,
          );

    return Stack(
      fit: StackFit.expand,
      children: [
        fallback,
        image,
      ],
    );
  }
}
