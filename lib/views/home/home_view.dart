import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../components/glass.dart';
import '../../components/app_loading_view.dart';
import '../../components/app_empty_view.dart';
import '../../components/cocktail_cover.dart';
import '../../components/drag_parallax_carousel.dart';
import '../../components/horizontal_edge_shadow.dart';
import '../../components/palette.dart';
import '../../core/theme/app_effects.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/interaction/app_feedback.dart';
import '../../models/cocktail.dart';
import '../../data/apis/api_providers.dart';
import '../../data/apis/cocktail_api.dart';
import '../../stores/cocktail_store.dart';
import '../../stores/settings_store.dart';
import '../../l10n/l10n.dart';
import 'widgets/featured_card.dart';
import 'widgets/waterfall_card.dart';

/// 今日推荐轮播下标。
final featIdxProvider = StateProvider<int>((ref) => 0);

// Divisible by every item count from 1 through 12, keeping the initial
// logical page stable while leaving ample room to loop in both directions.
const int _featuredLoopAnchor = 27720;
const Duration _featuredAutoTransitionDuration = Duration(milliseconds: 650);

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final PageController _featuredController;
  late final ScrollController _scrollController;
  late final AnimationController _gridEntranceController;
  late final Animation<double> _gridOpacity;
  final GlobalKey _categoryHeaderKey = GlobalKey();
  final Set<String> _preloadedFeaturedImages = {};
  Timer? _featuredLoopTimer;
  int _featuredCount = 0;
  bool _featuredLoopEnabled = false;
  bool _appIsActive = true;
  bool _gridEntranceInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appIsActive = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _featuredController = PageController(
      initialPage: _featuredLoopAnchor + ref.read(featIdxProvider),
      viewportFraction: .94,
    );
    _scrollController = ScrollController();
    _scrollController.addListener(_handleHomeScroll);
    _gridEntranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _gridOpacity = CurvedAnimation(
      parent: _gridEntranceController,
      curve: Curves.easeOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncAmbient();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loopEnabled = TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context);
    if (_featuredLoopEnabled != loopEnabled) {
      _featuredLoopEnabled = loopEnabled;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scheduleFeaturedLoop();
      });
    }
    if (_gridEntranceInitialized) return;
    _gridEntranceInitialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _playGridEntrance();
    });
  }

  void _syncAmbient() {
    final feats = ref.read(recommendationsProvider).valueOrNull;
    if (feats == null || feats.isEmpty) return;
    final f = feats[ref.read(featIdxProvider) % feats.length];
    ref.read(ambientColorProvider.notifier).state = f.themeColor;
  }

  void _preloadFeaturedImages(List<Cocktail> drinks) {
    if (!mounted) return;
    final media = MediaQuery.maybeOf(context);
    if (media == null) return;
    for (final drink in drinks) {
      final source = drink.coverImageUrl;
      if (source == null ||
          Uri.parse(source).path.toLowerCase().endsWith('.svg') ||
          !_preloadedFeaturedImages.add(source)) {
        continue;
      }
      final provider = ResizeImage.resizeIfNeeded(
        kCocktailCoverCacheWidth,
        null,
        NetworkImage(source),
      );
      precacheImage(
        provider,
        context,
        size: Size(media.size.width, 238),
      ).catchError((_) {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _featuredLoopTimer?.cancel();
    _featuredController.dispose();
    _scrollController.dispose();
    _gridEntranceController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appIsActive = state == AppLifecycleState.resumed;
    _scheduleFeaturedLoop();
  }

  void _scheduleFeaturedLoop() {
    _featuredLoopTimer?.cancel();
    _featuredLoopTimer = null;
    if (!_featuredLoopEnabled || !_appIsActive || _featuredCount <= 1) return;
    _featuredLoopTimer = Timer(
      const Duration(seconds: 3),
      () => unawaited(_advanceFeatured()),
    );
  }

  void _cancelFeaturedLoop() {
    _featuredLoopTimer?.cancel();
    _featuredLoopTimer = null;
  }

  Future<void> _advanceFeatured() async {
    if (!mounted ||
        !_featuredLoopEnabled ||
        !_appIsActive ||
        _featuredCount <= 1 ||
        !_featuredController.hasClients) {
      _scheduleFeaturedLoop();
      return;
    }
    final position = _featuredController.position;
    if (position.isScrollingNotifier.value) {
      _scheduleFeaturedLoop();
      return;
    }
    final current =
        (_featuredController.page ?? _featuredController.initialPage.toDouble())
            .round();
    await _featuredController.animateToPage(
      current + 1,
      duration: _featuredAutoTransitionDuration,
      curve: Curves.easeInOutCubic,
    );
    if (mounted) _scheduleFeaturedLoop();
  }

  void _animateFeaturedToLogical(int logicalIndex, int itemCount) {
    if (!_featuredController.hasClients || itemCount <= 0) return;
    final current =
        (_featuredController.page ?? _featuredController.initialPage.toDouble())
            .round();
    final cycleStart = current - current % itemCount;
    final candidates = <int>[
      cycleStart + logicalIndex,
      cycleStart + logicalIndex - itemCount,
      cycleStart + logicalIndex + itemCount,
    ]..sort(
        (a, b) => (a - current).abs().compareTo((b - current).abs()),
      );
    _featuredController.animateToPage(
      candidates.first,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppMotion.base,
      curve: AppMotion.standard,
    );
    _scheduleFeaturedLoop();
  }

  void _selectCategory(String? code) {
    if (code == ref.read(homeCategoryProvider)) return;
    final shouldResetScroll = _isCategoryHeaderPinned();
    _playGridEntrance();
    ref.read(homeCategoryProvider.notifier).state = code;
    if (!shouldResetScroll || !_scrollController.hasClients) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _scrollController.jumpTo(0);
    } else {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _loadMoreIfNeeded() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.extentAfter > 700) return;
    final category = ref.read(homeCategoryProvider);
    unawaited(ref.read(cocktailFeedProvider(category).notifier).loadMore());
  }

  // Kept as the stable ScrollController listener entry point so hot reloads
  // do not leave an existing HomeView state referencing a removed method.
  void _handleHomeScroll() {
    _loadMoreIfNeeded();
  }

  bool _isCategoryHeaderPinned() {
    if (!_scrollController.hasClients || _scrollController.offset <= 0) {
      return false;
    }
    final renderObject = _categoryHeaderKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return false;
    final headerTop = renderObject.localToGlobal(Offset.zero).dy;
    final viewportTop = MediaQuery.paddingOf(context).top;
    return headerTop <= viewportTop + 1;
  }

  void _playGridEntrance() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _gridEntranceController.value = 1;
      return;
    }
    _gridEntranceController.forward(from: 0);
  }

  String get _greeting {
    final hr = DateTime.now().hour;
    if (hr < 5) return 'Late Night';
    if (hr < 11) return 'Good Morning';
    if (hr < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final recommendations = ref.watch(recommendationsProvider);
    final cat = ref.watch(homeCategoryProvider);
    final feed = ref.watch(cocktailFeedProvider(cat));
    final categoryState = ref.watch(cocktailCategoriesProvider);
    final ambient = ref.watch(ambientColorProvider);
    ref.listen(recommendationsProvider, (previous, next) {
      if (next.hasError && previous?.hasError != true) {
        ref
            .read(toastProvider.notifier)
            .show(context.l10n.loadFailedDescription);
      }
    });
    ref.listen<CocktailFeedState>(cocktailFeedProvider(cat), (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        ref
            .read(toastProvider.notifier)
            .show(context.l10n.loadFailedDescription);
      }
    });
    ref.listen(cocktailCategoriesProvider, (previous, next) {
      if (next.hasError && previous?.hasError != true) {
        ref.read(toastProvider.notifier).show(context.l10n.categoryLoadFailed);
      }
    });
    if (recommendations.valueOrNull == null &&
        feed.items.isEmpty &&
        (recommendations.isLoading || feed.isLoading)) {
      return AppLoadingView(themeColor: ambient);
    }

    final feats = recommendations.valueOrNull ?? const <Cocktail>[];
    if (_featuredCount != feats.length) {
      _featuredCount = feats.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scheduleFeaturedLoop();
      });
    }
    if (feats.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _preloadFeaturedImages(feats);
      });
    }
    final featIdx = ref.watch(featIdxProvider);
    final categories = categoryState.valueOrNull ?? const <CocktailCategory>[];
    final grid = feed.items;
    // 推荐切换时同步氛围色
    ref.listen(featIdxProvider, (_, __) => _syncAmbient());
    ref.listen(recommendationsProvider, (_, __) => _syncAmbient());

    final topPad = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.only(top: topPad),
      child: CustomScrollView(
        controller: _scrollController,
        // 只保留视口前后约两屏内容，远处卡片会由 Sliver 回收。
        cacheExtent: 700,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              20,
              AppSpacing.gutter,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---- 头部：问候语 + 标题 + 月亮按钮 ----
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_greeting.toUpperCase(),
                                style: AppType.eyebrow(
                                    size: 13,
                                    tracking: .16,
                                    color:
                                        Colors.white.withValues(alpha: .45))),
                            const SizedBox(height: 9),
                            Text(context.l10n.appTitle,
                                style: AppType.serifZh(
                                    size: 30,
                                    height: 1.15,
                                    letterSpacing: -.3)),
                          ]),
                      GlassActionButton(
                        key: const ValueKey('home_search_action'),
                        label: context.l10n.search,
                        icon: PhosphorIcons.magnifyingGlass(),
                        appleSystemImageName: 'magnifyingglass',
                        showLabel: false,
                        width: 46,
                        height: 46,
                        onTap: () => context.push('/search'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // ---- 今日推荐：原生 PageView 手势轮播，不保留后台定时任务 ----
                  if (feats.isNotEmpty)
                    SizedBox(
                      height: 238,
                      child: DragParallaxCarousel(
                        controller: _featuredController,
                        itemCount: feats.length,
                        loop: true,
                        onInteractionStart: _cancelFeaturedLoop,
                        onInteractionEnd: _scheduleFeaturedLoop,
                        onPageChanged: (index) {
                          ref.read(featIdxProvider.notifier).state = index;
                          _scheduleFeaturedLoop();
                        },
                        itemBuilder: (context, index) {
                          final drink = feats[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: FeaturedCard(
                              key: ValueKey('featured_card_${drink.id}'),
                              drink: drink,
                              onTap: () => context.push(
                                '/detail/${drink.id}',
                                extra: drink,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  // ---- 轮播指示点（选中 20px 长条）----
                  SizedBox(
                    height: 44,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(feats.length, (i) {
                        final active =
                            i == featIdx % (feats.isEmpty ? 1 : feats.length);
                        return Semantics(
                          button: true,
                          selected: active,
                          label: '${i + 1}/${feats.length}',
                          child: GestureDetector(
                            excludeFromSemantics: true,
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              AppFeedback.selection();
                              _animateFeaturedToLogical(i, feats.length);
                            },
                            child: SizedBox(
                              width: 32,
                              height: 44,
                              child: Center(
                                child: AnimatedContainer(
                                  duration:
                                      MediaQuery.disableAnimationsOf(context)
                                          ? Duration.zero
                                          : AppMotion.base,
                                  curve: AppMotion.standard,
                                  width: active ? 20 : 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(99),
                                    color: active
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: .25),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _CategoryHeaderDelegate(
              headerKey: _categoryHeaderKey,
              child: HorizontalEdgeShadow(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 9),
                  itemBuilder: (context, i) {
                    final category = i == 0 ? null : categories[i - 1];
                    final code = category?.code;
                    return GlassChip(
                      label: category == null
                          ? context.l10n.all
                          : category.labelFor(
                              Localizations.localeOf(context).languageCode,
                            ),
                      selected: cat == code,
                      onTap: () => _selectCategory(code),
                    );
                  },
                ),
              ),
            ),
          ),
          SliverFadeTransition(
            opacity: _gridOpacity,
            sliver: feed.isLoading && grid.isEmpty
                ? SliverToBoxAdapter(
                    child: SizedBox(
                      height: 220,
                      child: AppLoadingView(themeColor: ambient),
                    ),
                  )
                : grid.isEmpty
                    ? SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.gutter,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: AppEmptyView(
                            icon: PhosphorIcons.martini(),
                            title: context.l10n.emptyCocktails,
                            subtitle: cat == null
                                ? context.l10n.cocktailsPreparing
                                : context.l10n.tryAnotherCategory,
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.gutter,
                        ),
                        sliver: SliverMasonryGrid.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childCount: grid.length,
                          itemBuilder: (context, index) {
                            final drink = grid[index];
                            return WaterfallCard(
                              key: ValueKey(drink.id),
                              drink: drink,
                              coverHeight: const [
                                132.0,
                                168.0,
                                150.0,
                                186.0,
                              ][index % 4],
                              onTap: () => context.push(
                                '/detail/${drink.id}',
                                extra: drink,
                              ),
                            );
                          },
                        ),
                      ),
          ),
          if (feed.isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 132)),
        ],
      ),
    );
  }
}

/// Flutter's sliver equivalent of CSS `position: sticky`: the category row
/// scrolls in its natural location and pins only after reaching the viewport.
class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _CategoryHeaderDelegate({
    required this.headerKey,
    required this.child,
  });

  static const height = 64.0;
  // A one-pixel collapse gives the delegate a reliable shrinkOffset signal
  // exactly when the header reaches its pinned position.
  static const _pinProbeExtent = 1.0;
  final GlobalKey headerKey;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height + _pinProbeExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final isPinned = shrinkOffset > .01 || overlapsContent;
    return SizedBox.expand(
      key: headerKey,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder: (currentChild, previousChildren) => Stack(
              fit: StackFit.expand,
              children: [
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            ),
            child: isPinned
                ? SizedBox.expand(
                    key: const ValueKey('category_sticky_glass'),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black,
                            Colors.black.withValues(alpha: 0.8),
                            Colors.black.withValues(alpha: 0.6),
                            Colors.black.withValues(alpha: 0.4),
                            Colors.black.withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  )
                : const SizedBox.expand(
                    key: ValueKey('category_sticky_transparent'),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              13,
              AppSpacing.gutter,
              13,
            ),
            child: child,
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CategoryHeaderDelegate oldDelegate) =>
      headerKey != oldDelegate.headerKey || child != oldDelegate.child;
}
