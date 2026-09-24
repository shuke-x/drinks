import 'package:flutter/cupertino.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../components/cocktail_cover.dart';
import '../../components/glass.dart';
import '../../components/palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/navigation/root_tab_bar_composition.dart';
import '../../models/cocktail.dart';
import '../../stores/cocktail_store.dart';
import '../../stores/my_cocktails_store.dart';
import '../../stores/user_store.dart';
import '../records/record_widgets.dart';

/// A making destination. Publishing/status management lives in Profile → Cellar.
class RecipesView extends ConsumerStatefulWidget {
  const RecipesView({super.key});
  @override
  ConsumerState<RecipesView> createState() => _RecipesViewState();
}

class _RecipesViewState extends ConsumerState<RecipesView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(ambientColorProvider.notifier).state = const Color(0xFF719F98);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final signedIn = ref.watch(userProvider.select((user) => user.isLoggedIn));
    final mine = signedIn ? ref.watch(myCocktailsProvider(null)) : null;
    final recommended = !signedIn ? ref.watch(recommendationsProvider) : null;
    final drinks = mine?.items ??
        recommended?.valueOrNull?.take(3).toList() ??
        <Cocktail>[];
    final loading = mine?.isLoading ?? recommended?.isLoading ?? false;
    final failed = mine?.error != null || (recommended?.hasError ?? false);
    void create() => context
        .push(signedIn ? '/upload?private=true' : '/login?returnTo=/recipes');
    void retry() {
      if (signedIn) {
        ref.read(myCocktailsProvider(null).notifier).loadFirstPage();
      } else {
        ref.invalidate(recommendationsProvider);
      }
    }

    return CustomScrollView(slivers: [
      SliverPadding(
          padding: EdgeInsets.fromLTRB(
              24, MediaQuery.paddingOf(context).top + 24, 24, 24),
          sliver: SliverToBoxAdapter(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('MAKE IT YOURS', style: AppType.eyebrow()),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: Text(recordText(context, '配方', 'Recipes'),
                        style: AppType.serifZh(size: 30))),
                CupertinoButton(
                    key: const ValueKey('create_recipe'),
                    onPressed: create,
                    child: Icon(PhosphorIcons.plus(),
                        semanticLabel:
                            recordText(context, '创建配方', 'Create recipe'))),
              ]),
              const SizedBox(height: 8),
              Text(
                  recordText(
                      context,
                      signedIn ? '从自己的版本开始，调一杯，再记下新的发现。' : '先从经典开始，再留下属于你的版本。',
                      signedIn
                          ? 'Make your own version, then keep a note of what you discover.'
                          : 'Start with a classic. Make it your own.'),
                  style: AppType.sans(
                      size: 15, height: 1.6, color: Colors.white70)),
              const SizedBox(height: 22),
              Text(
                  recordText(context, signedIn ? '我的配方' : '值得一试的配方',
                      signedIn ? 'My recipes' : 'Recipes to try'),
                  style: AppType.serifZh(size: 20)),
            ]),
          )),
      if (loading && drinks.isEmpty)
        const SliverToBoxAdapter(
            child: Center(child: CupertinoActivityIndicator())),
      if (failed)
        SliverToBoxAdapter(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  Text(recordText(context, '暂时无法加载配方，请重试。',
                      'Could not load recipes. Please retry.')),
                  CupertinoButton(
                      onPressed: retry,
                      child: Text(recordText(context, '重试', 'Retry'))),
                ]))),
      SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList.separated(
            itemCount: drinks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final drink = drinks[index];
              return InkWell(
                  onTap: () => context.push(
                      '/detail/${drink.id}${signedIn ? '?editable=true' : ''}',
                      extra: drink),
                  child: RecordSurface(
                      child: Row(children: [
                    ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: SizedBox(
                            width: 72,
                            height: 88,
                            child: CocktailCover(drink: drink))),
                    const SizedBox(width: 16),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(drink.nameFor(languageCode),
                              style: languageCode == 'en'
                                  ? AppType.cocktailEnglish(size: 19)
                                  : AppType.serifZh(size: 21)),
                          const SizedBox(height: 8),
                          Text(drink.cardTips.join(' · '),
                              style: AppType.sans(
                                  size: 13, color: Colors.white70)),
                        ])),
                    Icon(PhosphorIcons.caretRight(), size: 16),
                  ])));
            },
          )),
      if (signedIn && (mine?.hasMore ?? false) && drinks.isNotEmpty)
        SliverToBoxAdapter(
            child: CupertinoButton(
                onPressed: mine!.isLoadingMore
                    ? null
                    : () =>
                        ref.read(myCocktailsProvider(null).notifier).loadMore(),
                child: mine.isLoadingMore
                    ? const CupertinoActivityIndicator()
                    : Text(recordText(context, '加载更多', 'Load more')))),
      if (!signedIn || (!loading && !failed && drinks.isEmpty))
        SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverToBoxAdapter(
                child: RecordSurface(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                  Icon(PhosphorIcons.bookOpen(),
                      color: const Color(0xFFB2D8CF), size: 30),
                  const SizedBox(height: 18),
                  Text(
                      recordText(context, '你的第一份配方，从这里开始',
                          'Your first recipe starts here'),
                      style: AppType.serifZh(size: 23)),
                  const SizedBox(height: 10),
                  Text(
                      recordText(
                          context,
                          signedIn
                              ? '创建一份私人配方，或把调酒记录里的版本另存为配方。'
                              : '登录后创建自己的配方；草稿、私藏和发布管理都收纳在「我的 · 酒柜」。',
                          signedIn
                              ? 'Create a private recipe, or save a version from your tasting journal.'
                              : 'Sign in to create recipes. Manage drafts, private recipes and publishing in Profile → Cellar.'),
                      style: AppType.sans(
                          size: 15, height: 1.6, color: Colors.white70)),
                  const SizedBox(height: 20),
                  ValueListenableBuilder<bool>(
                      valueListenable: RootTabBarComposition.visible,
                      builder: (context, visible, _) => GlassActionButton(
                          useNative: visible,
                          label: recordText(
                              context,
                              signedIn ? '创建我的配方' : '登录，创建我的配方',
                              signedIn
                                  ? 'Create my recipe'
                                  : 'Sign in to create'),
                          onTap: create)),
                ])))),
      if (signedIn)
        SliverToBoxAdapter(
            child: CupertinoButton(
                onPressed: () => context.push('/private'),
                child: Text(recordText(context, '前往酒柜管理草稿与发布',
                    'Manage drafts and publishing in Cellar')))),
      SliverToBoxAdapter(
          child: SizedBox(height: 132 + MediaQuery.paddingOf(context).bottom)),
    ]);
  }
}
