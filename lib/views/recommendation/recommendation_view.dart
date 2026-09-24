export '../../models/flavor_direction.dart';
import '../../models/flavor_direction.dart';
import '../../stores/flavor_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../components/app_empty_view.dart';
import '../../components/app_loading_view.dart';
import '../../components/cocktail_cover.dart';
import '../../components/frosted_page_overlay.dart';
import '../../components/glass.dart';
import '../../core/interaction/app_feedback.dart';
import '../../core/theme/app_effects.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../models/cocktail.dart';
import '../../stores/cocktail_store.dart';
import 'recommendation_books_results.dart';
import '../detail/detail_view.dart';
import '../../core/navigation/anchored_detail_dialog.dart';

/// Root-tab adapter for the flavor recommendation experience.
///
/// Tests and Widget Preview can provide [previewDrinks] so the screen remains
/// independent from network, authentication, and local persistence.
class RecommendationView extends ConsumerWidget {
  const RecommendationView({
    super.key,
    this.previewDrinks,
    this.previewLoading = false,
    this.previewError = false,
    this.onOpenDrink,
  });

  final List<Cocktail>? previewDrinks;
  final bool previewLoading;
  final bool previewError;
  final ValueChanged<Cocktail>? onOpenDrink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final builtin = ref.watch(builtinDrinksProvider);
    final localPreviewDrinks = previewDrinks;
    final catalog = localPreviewDrinks != null
        ? const AsyncData(flavorDirections)
        : ref.watch(flavorDirectionsProvider);
    final List<Cocktail> drinks =
        localPreviewDrinks ?? ref.watch(allDrinksProvider) ?? const [];
    final loading = localPreviewDrinks != null
        ? previewLoading
        : builtin.isLoading && drinks.isEmpty;
    final error = localPreviewDrinks != null
        ? previewError
        : builtin.hasError && drinks.isEmpty;

    return RecommendationExperience(
      drinks: drinks,
      directions: catalog.valueOrNull ?? const [],
      loading: loading || catalog.isLoading,
      error: error || catalog.hasError,
      onRetry: localPreviewDrinks != null
          ? null
          : () {
              ref.invalidate(builtinDrinksProvider);
              ref.invalidate(flavorDirectionsProvider);
            },
      onOpenDrink: onOpenDrink ??
          (drink) => context.push('/detail/${drink.id}', extra: drink),
      onOpenFlavor: (flavor, featuredIndex) => context.push(
        '/recommend/${flavor.id}?pick=$featuredIndex',
      ),
    );
  }
}

typedef FlavorOpenCallback = void Function(
  FlavorDirection flavor,
  int featuredIndex,
);

/// Secondary flavor page used by `/recommend/:flavorId`.
///
/// The router presents this widget with the same Cupertino page class used by
/// `/detail/:id`, preserving the interactive iOS back gesture.
class FlavorRecommendationView extends ConsumerWidget {
  const FlavorRecommendationView({
    super.key,
    required this.flavorId,
    this.initialFeaturedIndex = 0,
  });

  final String flavorId;
  final int initialFeaturedIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(flavorDirectionsProvider);
    if (catalog.isLoading) return const Scaffold(body: AppLoadingView());
    if (catalog.hasError) {
      return Scaffold(
          body: AppEmptyView(
        icon: PhosphorIcons.cloudSlash(),
        subtitle: Localizations.localeOf(context).languageCode == 'en'
            ? 'Check your connection and try again.'
            : '请检查网络后重试。',
        title: Localizations.localeOf(context).languageCode == 'en'
            ? 'Unable to load flavors'
            : '风味暂时无法读取',
        actionLabel: Localizations.localeOf(context).languageCode == 'en'
            ? 'Retry'
            : '重试',
        onAction: () => ref.invalidate(flavorDirectionsProvider),
      ));
    }
    FlavorDirection? flavor;
    for (final item in catalog.requireValue) {
      if (item.id == flavorId) {
        flavor = item;
        break;
      }
    }
    final builtin = ref.watch(builtinDrinksProvider);
    final drinks = ref.watch(allDrinksProvider);
    final language = Localizations.localeOf(context).languageCode;

    if (flavor == null) {
      return FrostedPageOverlay(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: AppEmptyView(
            icon: PhosphorIcons.warningCircle(),
            title: language == 'en' ? 'Flavor not found' : '没有找到这个风味',
            subtitle: language == 'en'
                ? 'Return to the flavor list and choose another direction.'
                : '返回风味列表，再选择一个方向。',
            actionLabel: language == 'en' ? 'Go back' : '返回',
            onAction: () => context.pop(),
          ),
        ),
      );
    }

    if (builtin.isLoading && drinks.isEmpty) {
      return const FrostedPageOverlay(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: AppLoadingView(),
        ),
      );
    }

    return FrostedPageOverlay(
      child: FlavorRecommendationPage(
        flavor: flavor,
        drinks: rankDrinksForFlavor(drinks, flavor),
        initialFeaturedIndex: initialFeaturedIndex,
        loadFailed: builtin.hasError && drinks.isEmpty,
        onRetry: () => ref.invalidate(builtinDrinksProvider),
        onBack: () => context.pop(),
        onOpenDrink: (drink) =>
            context.push('/detail/${drink.id}', extra: drink),
        onOpenDrinkFromRect: (drink, rect) => showAnchoredDetailDialog(
          context: context,
          sourceRect: rect,
          destinationImageHeight:
              DetailView.artworkHeight + MediaQuery.paddingOf(context).top,
          preview: CocktailCover(drink: drink),
          builder: (_) => DetailView(id: drink.id, initialDrink: drink),
        ),
      ),
    );
  }
}

class FlavorRecommendationPage extends StatelessWidget {
  const FlavorRecommendationPage({
    super.key,
    required this.flavor,
    required this.drinks,
    required this.onBack,
    required this.onOpenDrink,
    this.onOpenDrinkFromRect,
    this.initialFeaturedIndex = 0,
    this.loadFailed = false,
    this.onRetry,
    this.reserveTabBarSpace = false,
  });

  final FlavorDirection flavor;
  final List<Cocktail> drinks;
  final VoidCallback onBack;
  final ValueChanged<Cocktail> onOpenDrink;
  final Future<void> Function(Cocktail drink, Rect rect)? onOpenDrinkFromRect;
  final int initialFeaturedIndex;
  final bool loadFailed;
  final VoidCallback? onRetry;
  final bool reserveTabBarSpace;

  @override
  Widget build(BuildContext context) => RecommendationBooksResults(
        flavorName: flavor.nameFor(
          Localizations.localeOf(context).languageCode,
        ),
        flavorSubtitle: flavor.subtitleFor(
          Localizations.localeOf(context).languageCode,
        ),
        accentColor: flavor.color,
        drinks: drinks,
        onBack: onBack,
        onOpenDrink: onOpenDrink,
        onOpenDrinkFromRect: onOpenDrinkFromRect,
        loadFailed: loadFailed,
        onRetry: onRetry,
        reserveTabBarSpace: reserveTabBarSpace,
      );
}

class RecommendationExperience extends StatefulWidget {
  const RecommendationExperience({
    super.key,
    required this.drinks,
    required this.onOpenDrink,
    this.loading = false,
    this.error = false,
    this.onRetry,
    this.initialFlavorId,
    this.onOpenFlavor,
    this.directions = flavorDirections,
  });

  final List<FlavorDirection> directions;
  final List<Cocktail> drinks;
  final ValueChanged<Cocktail> onOpenDrink;
  final bool loading;
  final bool error;
  final VoidCallback? onRetry;
  final String? initialFlavorId;
  final FlavorOpenCallback? onOpenFlavor;

  @override
  State<RecommendationExperience> createState() =>
      _RecommendationExperienceState();
}

class _RecommendationExperienceState extends State<RecommendationExperience> {
  String? _detailFlavorId;
  final Map<String, int> _featuredIndices = {};

  @override
  void initState() {
    super.initState();
    _detailFlavorId = widget.initialFlavorId;
  }

  FlavorDirection? get _detailFlavor {
    final id = _detailFlavorId;
    if (id == null) return null;
    for (final flavor in widget.directions) {
      if (flavor.id == id) return flavor;
    }
    return null;
  }

  void _showFlavor(FlavorDirection flavor) {
    AppFeedback.selection();
    final onOpenFlavor = widget.onOpenFlavor;
    if (onOpenFlavor != null) {
      onOpenFlavor(flavor, 0);
      return;
    }
    setState(() => _detailFlavorId = flavor.id);
  }

  void _showRandomFlavor() {
    if (widget.drinks.isEmpty || widget.directions.isEmpty) return;
    final seed = DateTime.now().microsecondsSinceEpoch;
    final flavor = widget.directions[seed % widget.directions.length];
    final ranked = rankDrinksForFlavor(widget.drinks, flavor);
    final featuredIndex = seed % ranked.length;
    final onOpenFlavor = widget.onOpenFlavor;
    if (onOpenFlavor != null) {
      AppFeedback.impact();
      onOpenFlavor(flavor, featuredIndex);
      return;
    }
    setState(() {
      _detailFlavorId = flavor.id;
      _featuredIndices[flavor.id] = featuredIndex;
    });
    AppFeedback.impact();
  }

  void _showPicker() => setState(() => _detailFlavorId = null);

  @override
  Widget build(BuildContext context) {
    final detailFlavor = _detailFlavor;
    return PopScope(
      canPop: detailFlavor == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _detailFlavor != null) _showPicker();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : AppMotion.base,
          switchInCurve: AppMotion.standard,
          switchOutCurve: AppMotion.standard,
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: detailFlavor == null
              ? _FlavorPickerPage(
                  key: const ValueKey('flavor_picker_page'),
                  directions: widget.directions,
                  drinks: widget.drinks,
                  loading: widget.loading,
                  error: widget.error,
                  onRetry: widget.onRetry,
                  onSurprise: _showRandomFlavor,
                  onViewAll: _showFlavor,
                )
              : FlavorRecommendationPage(
                  key: ValueKey('flavor_results_${detailFlavor.id}'),
                  flavor: detailFlavor,
                  drinks: rankDrinksForFlavor(widget.drinks, detailFlavor),
                  initialFeaturedIndex: _featuredIndices[detailFlavor.id] ?? 0,
                  onBack: _showPicker,
                  onOpenDrink: widget.onOpenDrink,
                  reserveTabBarSpace: true,
                ),
        ),
      ),
    );
  }
}

class _FlavorPickerPage extends StatelessWidget {
  const _FlavorPickerPage({
    super.key,
    required this.drinks,
    required this.directions,
    required this.loading,
    required this.error,
    required this.onSurprise,
    required this.onViewAll,
    this.onRetry,
  });

  final List<FlavorDirection> directions;
  final List<Cocktail> drinks;
  final bool loading;
  final bool error;
  final VoidCallback onSurprise;
  final ValueChanged<FlavorDirection> onViewAll;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return CustomScrollView(
      key: const PageStorageKey('recommendation_picker_scroll'),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            top + 26,
            AppSpacing.gutter,
            0,
          ),
          sliver: SliverList.list(
            children: [
              Semantics(
                header: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TONIGHT',
                      style: AppType.eyebrow(
                        size: 11,
                        tracking: .18,
                        color: Colors.white.withValues(alpha: .46),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      language == 'en' ? 'What are you craving?' : '现在想喝什么',
                      key: const ValueKey('recommendation_title'),
                      style: AppType.serifZh(size: 30, height: 1.15),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      language == 'en'
                          ? 'Start with a flavor. We will find a pour that fits the moment.'
                          : '从一种风味出发，找到最贴合此刻心情的那一杯。',
                      style: AppType.sans(
                        size: 15,
                        height: 1.55,
                        color: Colors.white.withValues(alpha: .62),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        if (loading)
          const SliverToBoxAdapter(
            child: SizedBox(height: 320, child: AppLoadingView()),
          )
        else if (error)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 340,
              child: AppEmptyView(
                icon: PhosphorIcons.cloudSlash(),
                title:
                    language == 'en' ? 'Could not load the menu' : '酒单暂时没有加载成功',
                subtitle: language == 'en'
                    ? 'Check your connection, then try again.'
                    : '请检查网络后重试，已经保存的内容不会受影响。',
                actionLabel: onRetry == null
                    ? null
                    : (language == 'en' ? 'Try again' : '重新加载'),
                onAction: onRetry,
              ),
            ),
          )
        else if (drinks.isEmpty || directions.isEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 340,
              child: AppEmptyView(
                icon: PhosphorIcons.martini(),
                title: language == 'en' ? 'No matches yet' : '还没有可推荐的酒款',
                subtitle: language == 'en'
                    ? 'Once the menu is ready, your flavor directions will appear here.'
                    : '酒单准备好后，五种风味方向会出现在这里。',
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FlavorSelectionModule(
                    directions: directions,
                    drinks: drinks,
                    language: language,
                    onSelect: onViewAll,
                    onSurprise: onSurprise,
                  ),
                ],
              ),
            ),
          ),
        SliverToBoxAdapter(child: SizedBox(height: bottom + 112)),
      ],
    );
  }
}

class _FlavorSelectionModule extends StatelessWidget {
  const _FlavorSelectionModule({
    required this.drinks,
    required this.directions,
    required this.language,
    required this.onSelect,
    required this.onSurprise,
  });

  final List<FlavorDirection> directions;
  final List<Cocktail> drinks;
  final String language;
  final ValueChanged<FlavorDirection> onSelect;
  final VoidCallback onSurprise;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            language == 'en' ? 'CHOOSE A MOOD' : '选择今晚的味道',
            key: const ValueKey('flavor_selector_title'),
            style: AppType.eyebrow(
              size: 10,
              tracking: .13,
              color: Colors.white.withValues(alpha: .64),
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < directions.length; index++) ...[
            _FlavorChoiceItem(
              key: ValueKey('view_all_${directions[index].id}'),
              flavor: directions[index],
              language: language,
              drink: rankDrinksForFlavor(
                drinks,
                directions[index],
              ).first,
              imageOnEnd: index.isOdd,
              onTap: () => onSelect(directions[index]),
            ),
            if (index != directions.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
          _FlavorChoiceItem.surprise(
            key: const ValueKey('surprise_flavor'),
            language: language,
            onTap: onSurprise,
          ),
        ],
      );
}

class _FlavorChoiceItem extends StatelessWidget {
  const _FlavorChoiceItem({
    super.key,
    required this.flavor,
    required this.language,
    required this.drink,
    required this.imageOnEnd,
    required this.onTap,
  }) : surprise = false;

  const _FlavorChoiceItem.surprise({
    super.key,
    required this.language,
    required this.onTap,
  })  : flavor = null,
        drink = null,
        imageOnEnd = false,
        surprise = true;

  final FlavorDirection? flavor;
  final String language;
  final Cocktail? drink;
  final bool imageOnEnd;
  final VoidCallback onTap;
  final bool surprise;

  @override
  Widget build(BuildContext context) {
    final item = flavor;
    final color = item?.color ?? const Color(0xFFAFA79B);
    final title = surprise
        ? (language == 'en' ? 'Surprise me' : '随便帮我选')
        : item!.nameFor(language);
    final subtitle = surprise
        ? (language == 'en' ? 'Leave it to tonight' : '把选择交给今晚')
        : item!.subtitleFor(language);

    if (surprise) {
      return Semantics(
        button: true,
        label: '$title，$subtitle',
        child: ExcludeSemantics(
          child: PressScale(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Row(
                children: [
                  Icon(
                    PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                    size: 18,
                    color: color,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: AppType.sans(
                        size: 15,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Icon(
                  //   PhosphorIcons.arrowRight(),
                  //   size: 18,
                  //   color: Colors.white.withValues(alpha: .54),
                  // ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final artwork = SizedBox(
      key: ValueKey('flavor_artwork_${item!.id}'),
      width: 132,
      height: 132,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: drink == null
            ? ColoredBox(color: color.withValues(alpha: .24))
            : CocktailCover(drink: drink!),
      ),
    );
    final copy = Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: imageOnEnd ? TextAlign.end : TextAlign.start,
            style: AppType.serifZh(size: 21, height: 1.16),
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            key: ValueKey('flavor_tip_${item.id}'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: imageOnEnd ? TextAlign.end : TextAlign.start,
            style: AppType.sans(
              size: 12,
              height: 1.42,
              color: Colors.white.withValues(alpha: .55),
            ),
          ),
        ],
      ),
    );
    const gap = SizedBox(width: 18);

    return Semantics(
      button: true,
      label: '$title，$subtitle',
      hint: language == 'en'
          ? 'Opens matching cocktail recommendations'
          : '打开匹配的鸡尾酒推荐',
      child: ExcludeSemantics(
        child: PressScale(
          onTap: onTap,
          scale: .985,
          child: Container(
            constraints: const BoxConstraints(minHeight: 132),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .045),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: .065)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(19),
              child: Row(
                children:
                    imageOnEnd ? [copy, gap, artwork] : [artwork, gap, copy],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Legacy implementation retained temporarily while the new direction is
// validated against production data.
// ignore: unused_element
class _TonightInspiration extends StatelessWidget {
  const _TonightInspiration({
    required this.drinks,
    required this.language,
    required this.onOpenDrink,
  });

  final List<Cocktail> drinks;
  final String language;
  final ValueChanged<Cocktail> onOpenDrink;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              language == 'en' ? 'Tonight’s inspiration' : '今晚灵感',
              key: const ValueKey('tonight_inspiration_title'),
              style: AppType.serifZh(size: 20, height: 1.15),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            language == 'en'
                ? 'A few quick ideas before you decide.'
                : '还没决定风味，也可以先随手看看。',
            style: AppType.sans(
              size: 12,
              color: Colors.white.withValues(alpha: .46),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 148,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: drinks.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final drink = drinks[index];
                return SizedBox(
                  width: 126,
                  child: _CompactDrinkCard(
                    drink: drink,
                    language: language,
                    onTap: () => onOpenDrink(drink),
                  ),
                );
              },
            ),
          ),
        ],
      );
}

class _CompactDrinkCard extends StatelessWidget {
  const _CompactDrinkCard({
    required this.drink,
    required this.language,
    required this.onTap,
  });

  final Cocktail drink;
  final String language;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: drink.nameFor(language),
        hint: language == 'en' ? 'Opens cocktail details' : '打开鸡尾酒详情',
        child: ExcludeSemantics(
          child: PressScale(
            onTap: onTap,
            scale: .97,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CocktailCover(drink: drink),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF0D0B10).withValues(alpha: .14),
                          const Color(0xFF0D0B10).withValues(alpha: .9),
                        ],
                        stops: const [.28, .56, 1],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .13),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    start: 11,
                    end: 11,
                    bottom: 11,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          drink.nameFor(language),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: language == 'en'
                              ? AppType.cocktailEnglish(
                                  size: 12.5, height: 1.18)
                              : AppType.serifZh(size: 13, height: 1.18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${drink.abv}% ABV',
                          style: AppType.mono(
                            size: 9,
                            color: Colors.white.withValues(alpha: .56),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

// ignore: unused_element
class _FlavorResultsPage extends StatelessWidget {
  const _FlavorResultsPage({
    required this.flavor,
    required this.drinks,
    required this.featuredIndex,
    required this.onBack,
    required this.onShuffle,
    required this.onOpenDrink,
    required this.loadFailed,
    required this.reserveTabBarSpace,
    // ignore: unused_element_parameter
    this.onRetry,
  });

  final FlavorDirection flavor;
  final List<Cocktail> drinks;
  final int featuredIndex;
  final VoidCallback onBack;
  final VoidCallback onShuffle;
  final ValueChanged<Cocktail> onOpenDrink;
  final bool loadFailed;
  final VoidCallback? onRetry;
  final bool reserveTabBarSpace;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final header = _ResultsHeader(
      flavor: flavor,
      language: language,
      onBack: onBack,
    );
    final headerExtent = top + 64;
    final background = Positioned.fill(
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(.72, -.86),
              radius: 1.08,
              colors: [
                flavor.color.withValues(alpha: .22),
                const Color(0xFF0D0B10).withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
    final pinnedHeader = Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(0, top + 8, 0, 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0D0B10),
              const Color(0xFF0D0B10).withValues(alpha: .9),
              const Color(0xFF0D0B10).withValues(alpha: 0),
            ],
            stops: const [0, .72, 1],
          ),
        ),
        child: header,
      ),
    );

    if (loadFailed || drinks.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            background,
            Padding(
              padding: EdgeInsets.only(top: headerExtent),
              child: AppEmptyView(
                icon: loadFailed ? PhosphorIcons.cloudSlash() : flavor.icon,
                title: loadFailed
                    ? (language == 'en'
                        ? 'Could not load recommendations'
                        : '推荐暂时没有加载成功')
                    : (language == 'en' ? 'No matches yet' : '暂时没有匹配酒款'),
                subtitle: loadFailed
                    ? (language == 'en'
                        ? 'Check your connection, then try again.'
                        : '请检查网络后重试，或先返回选择其他风味。')
                    : (language == 'en'
                        ? 'Return to the flavor list and try another direction.'
                        : '先返回风味列表，试试另一个方向。'),
                actionLabel: loadFailed && onRetry != null
                    ? (language == 'en' ? 'Try again' : '重新加载')
                    : (language == 'en' ? 'Back to flavors' : '返回风味选择'),
                onAction: loadFailed && onRetry != null ? onRetry : onBack,
              ),
            ),
            pinnedHeader,
          ],
        ),
      );
    }

    final normalizedIndex = featuredIndex % drinks.length;
    final featured = drinks[normalizedIndex];
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          background,
          CustomScrollView(
            key: PageStorageKey('flavor_results_${flavor.id}'),
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: headerExtent + 8)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                ),
                sliver: SliverList.list(
                  children: [
                    _FlavorProfileCard(
                      flavor: flavor,
                      language: language,
                      matchCount: drinks.length,
                    ),
                    const SizedBox(height: 28),
                    Semantics(
                      header: true,
                      child: Text(
                        language == 'en' ? 'Tonight’s first pour' : '今晚的首选推荐',
                        key: const ValueKey('flavor_results_title'),
                        style: AppType.serifZh(size: 28, height: 1.15),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      language == 'en'
                          ? 'Swipe the card or tap another one to keep exploring.'
                          : '左右滑动首选卡，或点击“换一杯”继续探索。',
                      style: AppType.sans(
                        size: 14,
                        height: 1.5,
                        color: Colors.white.withValues(alpha: .58),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragEnd: drinks.length < 2
                          ? null
                          : (details) {
                              final velocity =
                                  details.primaryVelocity?.abs() ?? 0;
                              if (velocity > 120) onShuffle();
                            },
                      child: AnimatedSwitcher(
                        duration: reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          if (reduceMotion) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          }
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: Tween(begin: .985, end: 1.0)
                                  .animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: _FeaturedRecommendationCard(
                          key: ValueKey('featured_${featured.id}'),
                          drink: featured,
                          flavor: flavor,
                          language: language,
                          onTap: () => onOpenDrink(featured),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _RecommendationProgress(
                            total: drinks.length,
                            selected: normalizedIndex,
                            color: flavor.color,
                            language: language,
                          ),
                        ),
                        GlassActionButton(
                          key: const ValueKey('shuffle_recommendation'),
                          label: language == 'en' ? 'Another one' : '换一杯',
                          icon: PhosphorIcons.arrowsClockwise(),
                          appleSystemImageName: 'arrow.triangle.2.circlepath',
                          height: 44,
                          onTap: drinks.length > 1 ? onShuffle : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 38),
                    Semantics(
                      header: true,
                      child: Text(
                        language == 'en' ? 'More to explore' : '更多风味探索',
                        style: AppType.serifZh(size: 22),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      language == 'en'
                          ? 'All matches, ordered by how closely they fit.'
                          : '按照风味匹配度排序，完整看看今晚还有哪些选择。',
                      style: AppType.sans(
                        size: 12.5,
                        color: Colors.white.withValues(alpha: .48),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                sliver: SliverList.separated(
                  itemCount: drinks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 11),
                  itemBuilder: (context, index) => _ResultDrinkRow(
                    key: ValueKey('result_drink_${drinks[index].id}'),
                    drink: drinks[index],
                    language: language,
                    rank: index + 1,
                    featured: index == normalizedIndex,
                    onTap: () => onOpenDrink(drinks[index]),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: bottom + (reserveTabBarSpace ? 112 : 36),
                ),
              ),
            ],
          ),
          pinnedHeader,
        ],
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({
    required this.flavor,
    required this.language,
    required this.onBack,
  });

  final FlavorDirection flavor;
  final String language;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: SizedBox(
          height: 48,
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
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      flavor.nameFor(language),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.sans(
                        size: 14,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      language == 'en' ? 'FULL RECOMMENDATION' : '完整风味推荐',
                      style: AppType.mono(
                        size: 9,
                        color: Colors.white.withValues(alpha: .42),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _FlavorProfileCard extends StatelessWidget {
  const _FlavorProfileCard({
    required this.flavor,
    required this.language,
    required this.matchCount,
  });

  final FlavorDirection flavor;
  final String language;
  final int matchCount;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 128),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              flavor.color.withValues(alpha: .28),
              Colors.white.withValues(alpha: .055),
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: .14)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: flavor.color.withValues(alpha: .18),
                border: Border.all(
                  color: flavor.color.withValues(alpha: .52),
                ),
              ),
              child: Icon(flavor.icon, size: 24, color: flavor.color),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          flavor.nameFor(language),
                          style: AppType.serifZh(size: 21, height: 1.2),
                        ),
                      ),
                      InfoPill(
                        label: language == 'en'
                            ? '$matchCount MATCHES'
                            : '$matchCount 款匹配',
                        mono: true,
                        fontSize: 9,
                        fill: Colors.black.withValues(alpha: .18),
                        borderColor: Colors.white.withValues(alpha: .12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    flavor.subtitleFor(language),
                    style: AppType.sans(
                      size: 13,
                      height: 1.5,
                      color: Colors.white.withValues(alpha: .62),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _FeaturedRecommendationCard extends StatelessWidget {
  const _FeaturedRecommendationCard({
    super.key,
    required this.drink,
    required this.flavor,
    required this.language,
    required this.onTap,
  });

  final Cocktail drink;
  final FlavorDirection flavor;
  final String language;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: language == 'en'
            ? 'Top recommendation, ${drink.nameFor(language)}'
            : '首选推荐，${drink.nameFor(language)}',
        onTap: onTap,
        child: ExcludeSemantics(
          child: PressScale(
            onTap: onTap,
            scale: .982,
            child: Container(
              height: 330,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: flavor.color.withValues(alpha: .22),
                    blurRadius: 44,
                    offset: const Offset(0, 22),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CocktailCover(drink: drink),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: .06),
                            Colors.transparent,
                            const Color(0xFF0D0B10).withValues(alpha: .94),
                          ],
                          stops: const [0, .38, 1],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .17),
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      top: 20,
                      child: InfoPill(
                        label: language == 'en' ? 'TOP MATCH' : '首选推荐',
                        fill: flavor.color.withValues(alpha: .84),
                        borderColor: Colors.white.withValues(alpha: .22),
                      ),
                    ),
                    Positioned(
                      left: 22,
                      right: 22,
                      bottom: 22,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            drink.nameFor(language),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: language == 'en'
                                ? AppType.cocktailEnglish(
                                    size: 25,
                                    color: Colors.white,
                                  )
                                : AppType.serifZh(size: 28),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            '${drink.base}  ·  ${drink.abv}% ABV',
                            style: AppType.mono(
                              size: 11,
                              color: Colors.white.withValues(alpha: .65),
                            ),
                          ),
                          if (drink.flavor.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              drink.flavor,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.sans(
                                size: 13,
                                height: 1.45,
                                color: Colors.white.withValues(alpha: .68),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _RecommendationProgress extends StatelessWidget {
  const _RecommendationProgress({
    required this.total,
    required this.selected,
    required this.color,
    required this.language,
  });

  final int total;
  final int selected;
  final Color color;
  final String language;

  @override
  Widget build(BuildContext context) => Semantics(
        label: language == 'en'
            ? 'Recommendation ${selected + 1} of $total'
            : '第 ${selected + 1} 个推荐，共 $total 个',
        child: ExcludeSemantics(
          child: Row(
            children: [
              Text(
                '${(selected + 1).toString().padLeft(2, '0')} / '
                '${total.toString().padLeft(2, '0')}',
                style: AppType.mono(
                  size: 10.5,
                  color: Colors.white.withValues(alpha: .58),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: SizedBox(
                    height: 4,
                    child: LinearProgressIndicator(
                      value: (selected + 1) / total,
                      color: color,
                      backgroundColor: Colors.white.withValues(alpha: .14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      );
}

class _ResultDrinkRow extends StatelessWidget {
  const _ResultDrinkRow({
    super.key,
    required this.drink,
    required this.language,
    required this.rank,
    required this.featured,
    required this.onTap,
  });

  final Cocktail drink;
  final String language;
  final int rank;
  final bool featured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label:
            '$rank, ${drink.nameFor(language)}, ${drink.base}, ${drink.abv}% ABV',
        onTap: onTap,
        child: ExcludeSemantics(
          child: PressScale(
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 94),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: Colors.white.withValues(alpha: .065),
                border: Border.all(color: Colors.white.withValues(alpha: .11)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 74,
                    height: 74,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child: CocktailCover(drink: drink),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              rank.toString().padLeft(2, '0'),
                              style: AppType.mono(
                                size: 9.5,
                                color: drink.themeColor,
                              ),
                            ),
                            if (featured) ...[
                              const SizedBox(width: 8),
                              Text(
                                language == 'en' ? 'CURRENT PICK' : '当前首选',
                                style: AppType.mono(
                                  size: 8.5,
                                  color: Colors.white.withValues(alpha: .48),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          drink.nameFor(language),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: language == 'en'
                              ? AppType.cocktailEnglish(
                                  size: 15,
                                  color: Colors.white,
                                )
                              : AppType.serifZh(size: 17),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${drink.base}  ·  ${drink.abv}% ABV',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.sans(
                            size: 11.5,
                            color: Colors.white.withValues(alpha: .48),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    PhosphorIcons.caretRight(),
                    size: 17,
                    color: Colors.white.withValues(alpha: .38),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
