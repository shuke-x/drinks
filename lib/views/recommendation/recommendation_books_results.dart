import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../components/app_empty_view.dart';
import '../../components/cocktail_cover.dart';
import '../../components/common/common.dart';
import '../../components/drag_gallery_list.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../models/cocktail.dart';

/// Image-led, categorized recommendation shelves inspired by Apple's media
/// storefronts. The page scrolls vertically while each shelf keeps the
/// project's direct-manipulation horizontal drag behavior.
class RecommendationBooksResults extends StatelessWidget {
  const RecommendationBooksResults({
    super.key,
    required this.flavorName,
    required this.flavorSubtitle,
    required this.accentColor,
    required this.drinks,
    required this.onBack,
    required this.onOpenDrink,
    this.onOpenDrinkFromRect,
    required this.loadFailed,
    required this.reserveTabBarSpace,
    this.onRetry,
  });

  final String flavorName;
  final String flavorSubtitle;
  final Color accentColor;
  final List<Cocktail> drinks;
  final VoidCallback onBack;
  final ValueChanged<Cocktail> onOpenDrink;
  final Future<void> Function(Cocktail drink, Rect rect)? onOpenDrinkFromRect;
  final bool loadFailed;
  final bool reserveTabBarSpace;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final shelves = _shelvesFor(drinks, language);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(.84, -.9),
                    radius: 1.15,
                    colors: [
                      accentColor.withValues(alpha: .16),
                      const Color(0xFF0D0B10).withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (loadFailed || drinks.isEmpty)
            _EmptyResults(
              language: language,
              loadFailed: loadFailed,
              onRetry: onRetry,
              onBack: onBack,
            )
          else
            CustomScrollView(
              key: ValueKey('flavor_results_$flavorName'),
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _ResultsHeader(
                    language: language,
                    onBack: onBack,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.gutter,
                    18,
                    AppSpacing.gutter,
                    22,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          flavorName,
                          key: const ValueKey('flavor_results_title'),
                          style: AppType.serifZh(size: 36, height: 1.08),
                        ),
                        const SizedBox(height: 11),
                        Text(
                          flavorSubtitle,
                          style: AppType.sans(
                            size: 15,
                            height: 1.5,
                            color: Colors.white.withValues(alpha: .58),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                for (final shelf in shelves)
                  SliverToBoxAdapter(
                    child: _ShelfSection(
                      shelf: shelf,
                      language: language,
                      onOpenDrink: onOpenDrink,
                      onOpenDrinkFromRect: onOpenDrinkFromRect,
                    ),
                  ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: bottom + (reserveTabBarSpace ? 112 : 38),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({required this.language, required this.onBack});

  final String language;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(10, 7, 20, 0),
        child: Row(
          children: [
            GlassCircleButton(
              key: const ValueKey('recommendation_back'),
              icon: PhosphorIcons.caretLeft(),
              appleSystemImageName: 'chevron.left',
              semanticLabel: language == 'en' ? 'Back to flavors' : '返回风味选择',
              size: 44,
              iconSize: 18,
              onTap: onBack,
            ),
            const Spacer(),
            Text(
              language == 'en' ? 'FLAVOR EDIT' : '风味精选',
              style: AppType.eyebrow(
                size: 10,
                tracking: .14,
                color: Colors.white.withValues(alpha: .44),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShelfSection extends StatelessWidget {
  const _ShelfSection({
    required this.shelf,
    required this.language,
    required this.onOpenDrink,
    this.onOpenDrinkFromRect,
  });

  final _RecommendationShelf shelf;
  final String language;
  final ValueChanged<Cocktail> onOpenDrink;
  final Future<void> Function(Cocktail drink, Rect rect)? onOpenDrinkFromRect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shelf.title,
                  key: ValueKey('result_shelf_${shelf.id}'),
                  style: AppType.serifZh(size: 23, height: 1.15),
                ),
                const SizedBox(height: 5),
                Text(
                  shelf.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.sans(
                    size: 13,
                    color: Colors.white.withValues(alpha: .48),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Shelf(
            drinks: shelf.drinks,
            language: language,
            onOpenDrink: onOpenDrink,
            onOpenDrinkFromRect: onOpenDrinkFromRect,
          ),
        ],
      ),
    );
  }
}

class _Shelf extends StatelessWidget {
  const _Shelf({
    required this.drinks,
    required this.language,
    required this.onOpenDrink,
    this.onOpenDrinkFromRect,
  });

  final List<Cocktail> drinks;
  final String language;
  final ValueChanged<Cocktail> onOpenDrink;
  final Future<void> Function(Cocktail drink, Rect rect)? onOpenDrinkFromRect;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 220),
      child: KeyedSubtree(
        key: ValueKey(drinks.map((drink) => drink.id).join(',')),
        child: drinks.length == 1
            ? Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                ),
                child: SizedBox(
                  width: 198,
                  child: _ShelfCard(
                    drink: drinks.first,
                    language: language,
                    onTap: () => onOpenDrink(drinks.first),
                    onOpenFromRect: onOpenDrinkFromRect,
                  ),
                ),
              )
            : SizedBox(
                height: 204,
                child: DragGalleryList(
                  itemCount: drinks.length,
                  itemExtent: 198,
                  gap: 12,
                  dragScale: .98,
                  friction: .055,
                  backgroundColor: Colors.transparent,
                  padding: const EdgeInsetsDirectional.only(
                    start: AppSpacing.gutter,
                  ),
                  clipBehavior: Clip.none,
                  semanticLabel:
                      language == 'en' ? 'Cocktail recommendations' : '推荐酒款列表',
                  itemBuilder: (context, index) {
                    final drink = drinks[index];
                    return _ShelfCard(
                      drink: drink,
                      language: language,
                      onTap: () => onOpenDrink(drink),
                      onOpenFromRect: onOpenDrinkFromRect,
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _ShelfCard extends StatefulWidget {
  const _ShelfCard({
    required this.drink,
    required this.language,
    required this.onTap,
    this.onOpenFromRect,
  });

  final Cocktail drink;
  final String language;
  final VoidCallback onTap;
  final Future<void> Function(Cocktail drink, Rect rect)? onOpenFromRect;

  @override
  State<_ShelfCard> createState() => _ShelfCardState();
}

class _ShelfCardState extends State<_ShelfCard> {
  final imageKey = GlobalKey();
  bool _opening = false;

  Cocktail get drink => widget.drink;
  String get language => widget.language;

  @override
  Widget build(BuildContext context) {
    Future<void> open() async {
      if (_opening) return;
      final callback = widget.onOpenFromRect;
      final box = imageKey.currentContext?.findRenderObject();
      if (callback != null && box is RenderBox && box.hasSize) {
        final rect = MatrixUtils.transformRect(
          box.getTransformTo(null),
          Offset.zero & box.size,
        );
        setState(() => _opening = true);
        try {
          await callback(drink, rect);
        } finally {
          if (mounted) setState(() => _opening = false);
        }
      } else {
        widget.onTap();
      }
    }

    return Semantics(
      button: true,
      label: '${drink.nameFor(language)}, ${drink.base}, ${drink.abv}% ABV',
      hint: language == 'en' ? 'Opens cocktail details' : '打开鸡尾酒详情',
      onTap: open,
      child: ExcludeSemantics(
        child: PressScale(
          onTap: open,
          scale: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                key: imageKey,
                aspectRatio: 1.18,
                child: ClipRSuperellipse(
                  borderRadius: BorderRadius.circular(16),
                  child: Opacity(
                    key: ValueKey('flavor_source_image_${drink.id}'),
                    opacity: _opening ? 0 : 1,
                    child: CocktailCover(drink: drink),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                drink.nameFor(language),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: language == 'en'
                    ? AppType.cocktailEnglish(size: 14.5, color: Colors.white)
                    : AppType.serifZh(size: 16.5, height: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({
    required this.language,
    required this.loadFailed,
    required this.onRetry,
    required this.onBack,
  });

  final String language;
  final bool loadFailed;
  final VoidCallback? onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ResultsHeader(language: language, onBack: onBack),
        Expanded(
          child: AppEmptyView(
            icon: loadFailed
                ? PhosphorIcons.cloudSlash()
                : PhosphorIcons.martini(),
            title: loadFailed
                ? (language == 'en'
                    ? 'Unable to load recommendations'
                    : '推荐暂时没有加载成功')
                : (language == 'en' ? 'No matches yet' : '暂时没有匹配酒款'),
            subtitle: loadFailed
                ? (language == 'en'
                    ? 'Check your connection and try again.'
                    : '请检查网络后重试，或返回选择其他风味。')
                : (language == 'en'
                    ? 'Choose another flavor and keep exploring.'
                    : '返回风味列表，试试另一个方向。'),
            actionLabel: loadFailed && onRetry != null
                ? (language == 'en' ? 'Try again' : '重新加载')
                : (language == 'en' ? 'Back to flavors' : '返回风味选择'),
            onAction: loadFailed && onRetry != null ? onRetry : onBack,
          ),
        ),
      ],
    );
  }
}

class _RecommendationShelf {
  const _RecommendationShelf({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.drinks,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<Cocktail> drinks;
}

List<_RecommendationShelf> _shelvesFor(
  List<Cocktail> drinks,
  String language,
) {
  final definitions = <({
    String id,
    String zhTitle,
    String enTitle,
    String zhSubtitle,
    String enSubtitle,
    bool Function(Cocktail) matches,
  })>[
    (
      id: 'light',
      zhTitle: '轻盈开场',
      enTitle: 'Start Light',
      zhSubtitle: '低酒精度，清新而没有负担',
      enSubtitle: 'Bright, refreshing, and lower in alcohol',
      matches: (drink) => drink.abv <= 15,
    ),
    (
      id: 'balanced',
      zhTitle: '平衡风味',
      enTitle: 'Beautifully Balanced',
      zhSubtitle: '香气、酸甜与酒感恰到好处',
      enSubtitle: 'A composed balance of aroma, acidity, and spirit',
      matches: (drink) => drink.abv >= 16 && drink.abv <= 22,
    ),
    (
      id: 'bold',
      zhTitle: '酒感更足',
      enTitle: 'Spirit Forward',
      zhSubtitle: '轮廓深邃，适合慢慢品饮',
      enSubtitle: 'Deeper character, made for slow sipping',
      matches: (drink) => drink.abv >= 23,
    ),
  ];

  return definitions
      .map((definition) {
        final matching =
            drinks.where(definition.matches).toList(growable: false);
        return _RecommendationShelf(
          id: definition.id,
          title: language == 'en' ? definition.enTitle : definition.zhTitle,
          subtitle:
              language == 'en' ? definition.enSubtitle : definition.zhSubtitle,
          drinks: matching,
        );
      })
      .where((shelf) => shelf.drinks.isNotEmpty)
      .toList(growable: false);
}
