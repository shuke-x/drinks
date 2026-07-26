import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../components/glass.dart';
import '../../components/app_loading_view.dart';
import '../../components/palette.dart';
import '../../core/theme/app_effects.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../models/cocktail.dart';
import '../../stores/cocktail_store.dart';
import 'widgets/featured_card.dart';
import 'widgets/waterfall_card.dart';

/// 今日推荐轮播下标。
final featIdxProvider = StateProvider<int>((ref) => 0);

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  late final PageController _featuredController;

  @override
  void initState() {
    super.initState();
    _featuredController = PageController(
      initialPage: ref.read(featIdxProvider),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncAmbient();
    });
  }

  void _syncAmbient() {
    final feats = ref.read(recommendationsProvider).valueOrNull;
    if (feats == null || feats.isEmpty) return;
    final f = feats[ref.read(featIdxProvider) % feats.length];
    ref.read(ambientColorProvider.notifier).state = f.themeColor;
  }

  @override
  void dispose() {
    _featuredController.dispose();
    super.dispose();
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
    final drinks = ref.watch(builtinDrinksProvider);
    final ambient = ref.watch(ambientColorProvider);
    if (recommendations.isLoading || drinks.isLoading) {
      return AppLoadingView(themeColor: ambient);
    }

    final feats = recommendations.valueOrNull ?? const <Cocktail>[];
    final featIdx = ref.watch(featIdxProvider);
    final cat = ref.watch(homeCategoryProvider);
    final grid = ref.watch(homeGridProvider);

    // 推荐切换时同步氛围色
    ref.listen(featIdxProvider, (_, __) => _syncAmbient());
    ref.listen(recommendationsProvider, (_, __) => _syncAmbient());

    final topPad = MediaQuery.paddingOf(context).top;
    print('HomeView.build() ${grid.toList()}');

    // 瀑布流两列分配（原型：偶数下标进 A 列，奇数进 B 列）
    final colA = <(Cocktail, int)>[];
    final colB = <(Cocktail, int)>[];
    for (var i = 0; i < grid.length; i++) {
      (i.isEven ? colA : colB).add((grid[i], i));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.gutter, topPad + 20, AppSpacing.gutter, 132),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---- 头部：问候语 + 标题 + 月亮按钮 ----
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_greeting.toUpperCase(),
                    style: AppType.eyebrow(
                        size: 13,
                        tracking: .16,
                        color: Colors.white.withOpacity(.45))),
                const SizedBox(height: 9),
                Text('今晚喝什么',
                    style: AppType.serifZh(
                        size: 30, height: 1.15, letterSpacing: -.3)),
              ]),
              GlassCircleButton(
                  icon: PhosphorIcons.moonStars(), size: 42, iconSize: 19),
            ],
          ),
          const SizedBox(height: 22),

          // ---- 今日推荐：原生 PageView 手势轮播，不保留后台定时任务 ----
          if (feats.isNotEmpty)
            SizedBox(
              height: 238,
              child: PageView.builder(
                controller: _featuredController,
                itemCount: feats.length,
                onPageChanged: (index) {
                  ref.read(featIdxProvider.notifier).state = index;
                },
                itemBuilder: (context, index) => FeaturedCard(
                  drink: feats[index],
                  onTap: () => context.push('/detail/${feats[index].id}'),
                ),
              ),
            ),
          const SizedBox(height: 14),

          // ---- 轮播指示点（选中 20px 长条）----
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(feats.length, (i) {
              final active = i == featIdx % (feats.isEmpty ? 1 : feats.length);
              return GestureDetector(
                onTap: () => _featuredController.animateToPage(
                  i,
                  duration: AppMotion.base,
                  curve: AppMotion.standard,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 450),
                  curve: AppMotion.spring,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 20 : 5,
                  height: 5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color:
                        active ? Colors.white : Colors.white.withOpacity(.25),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // ---- 分类胶囊（横向滚动，出血到屏幕边缘）----
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: kCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 9),
              itemBuilder: (context, i) {
                final c = kCategories[i];
                return GlassChip(
                  label: c,
                  selected: cat == c,
                  onTap: () =>
                      ref.read(homeCategoryProvider.notifier).state = c,
                );
              },
            ),
          ),
          const SizedBox(height: 18),

          // ---- 双列瀑布流（B 列顶部下沉 24，形成错落）----
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _column(context, colA, 0)),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: _column(context, colB, 1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _column(BuildContext context, List<(Cocktail, int)> items, int col) {
    return Column(
      children: [
        for (final (d, i) in items) ...[
          WaterfallCard(
            drink: d,
            // 原型封面高度循环 [132,168,150,186]
            coverHeight: const [132.0, 168.0, 150.0, 186.0][i % 4],
            onTap: () => context.push('/detail/${d.id}'),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
