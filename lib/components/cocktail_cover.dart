import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/auth/token_storage.dart';
import '../core/config/env.dart';
import '../stores/user_store.dart';

import '../models/cocktail.dart';
import 'palette.dart';

/// 列表、Banner、Next 与详情统一使用同一解码缓存键。
const int kCocktailCoverCacheWidth = 1080;

/// 酒单卡片统一封面。
///
/// 服务端的 [Cocktail.images] 第一张有效完整 URL 优先展示；没有图片、空字符串
/// 或加载失败时回退到主题色渐变。
final _assetHeaders = FutureProvider.autoDispose
    .family<Map<String, String>, String>((ref, source) async {
  final user = ref.watch(userProvider);
  final uri = Uri.tryParse(source);
  final api = Uri.parse(Env.baseUrl);
  if (!user.isLoggedIn ||
      uri == null ||
      uri.origin != api.origin ||
      !uri.path.startsWith('/static/')) {
    return {};
  }
  final token = await TokenStorage.instance.readAccessToken();
  return token == null ? {} : {'Authorization': 'Bearer $token'};
});

class CocktailCover extends ConsumerWidget {
  const CocktailCover(
      {super.key, required this.drink, this.fit = BoxFit.cover});

  final Cocktail drink;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fallback = DecoratedBox(
      decoration: BoxDecoration(gradient: drinkGrad(drink.themeColor)),
      child: const SizedBox.expand(),
    );
    final source = drink.coverImageUrl;
    if (source == null) return fallback;

    final headers = ref.watch(_assetHeaders(source));
    if (headers.isLoading) return fallback;
    final isSvg = Uri.parse(source).path.toLowerCase().endsWith('.svg');
    final image = isSvg
        ? SvgPicture.network(
            source,
            fit: fit,
            headers: headers.valueOrNull ?? {},
            placeholderBuilder: (_) => fallback,
          )
        : Image.network(
            source,
            fit: fit,
            headers: headers.valueOrNull ?? {},
            cacheWidth: kCocktailCoverCacheWidth,
            filterQuality: FilterQuality.low,
            gaplessPlayback: true,
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : fallback,
            errorBuilder: (_, __, ___) => fallback,
          );

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [fallback, image],
      ),
    );
  }
}
