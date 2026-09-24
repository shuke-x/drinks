import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../components/app_loading_view.dart';
import '../../components/cocktail_cover.dart';
import '../../components/frosted_page_overlay.dart';
import '../../components/deck_card_list.dart';
import '../../components/glass.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../stores/cocktail_store.dart';
import '../../stores/settings_store.dart';
import '../../stores/user_store.dart';
import '../../stores/deck_store.dart';
import '../../l10n/l10n.dart';

class FavoritesView extends ConsumerStatefulWidget {
  const FavoritesView({super.key});
  @override
  ConsumerState<FavoritesView> createState() => _FavoritesViewState();
}

class _FavoritesViewState extends ConsumerState<FavoritesView>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final DeckController _deck = DeckController();
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final dt = (elapsed - _last).inMicroseconds / 1e6;
      _last = elapsed;
      _deck.tick(dt);
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _deck.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final user = ref.watch(userProvider);
    final drinks = ref
        .watch(allDrinksProvider)
        .where((d) => user.favoriteIds.contains(d.id))
        .toList();
    final builtin = ref.watch(builtinDrinksProvider);
    final top = MediaQuery.paddingOf(context).top;
    ref.listen(builtinDrinksProvider, (previous, next) {
      if (next.hasError && previous?.hasError != true) {
        ref
            .read(toastProvider.notifier)
            .show(context.l10n.loadFailedDescription);
      }
    });
    if (builtin.isLoading) {
      return const Scaffold(
          backgroundColor: Color(0xB80D0B10), body: AppLoadingView());
    }
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: FrostedPageOverlay(
            child: ListView(
                padding: EdgeInsets.fromLTRB(
                    AppSpacing.gutter, top + 12, AppSpacing.gutter, 42),
                children: [
              SizedBox(
                  height: 42,
                  child: Stack(alignment: Alignment.center, children: [
                    Text(context.l10n.myFavorites,
                        style: AppType.title(size: 18, height: 1.0)),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: GlassCircleButton(
                            icon: PhosphorIcons.arrowLeft(),
                            appleSystemImageName: 'chevron.left',
                            size: 38,
                            iconSize: 17,
                            semanticLabel: MaterialLocalizations.of(context)
                                .backButtonTooltip,
                            onTap: () => context.pop())),
                  ])),
              const SizedBox(height: 24),
              if (drinks.isEmpty)
                GlassCard(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        child: Column(children: [
                          Icon(PhosphorIcons.heart(),
                              color: Colors.white.withValues(alpha: .45),
                              size: 30),
                          const SizedBox(height: 12),
                          Text(context.l10n.noFavorites,
                              style: AppType.serifZh(size: 17)),
                          const SizedBox(height: 5),
                          Text(context.l10n.favoriteEmptyHint,
                              style: AppType.sans(
                                  size: 12.5,
                                  color: Colors.white.withValues(alpha: .45)))
                        ]))),
              if (drinks.length > 3)
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: SizedBox(
                    height: 570,
                    child: AnimatedBuilder(
                      animation: _deck,
                      builder: (context, child) => GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragStart: (details) =>
                            _deck.onDragStart(details.globalPosition.dx),
                        onHorizontalDragUpdate: (details) =>
                            _deck.onDragUpdate(details.globalPosition.dx),
                        onHorizontalDragEnd: (details) => _deck.onDragEnd(
                            details.primaryVelocity ?? 0,
                            MediaQuery.disableAnimationsOf(context)),
                        child: LayoutBuilder(
                          builder: (context, constraints) => DeckCardList(
                            drinks: drinks,
                            deck: _deck,
                            width: constraints.maxWidth,
                            onOpen: (drink) => context.push(
                              '/detail/${drink.id}',
                              extra: drink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                for (final drink in drinks)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 11),
                      child: PressScale(
                          onTap: () => context.push(
                                '/detail/${drink.id}',
                                extra: drink,
                              ),
                          child: GlassCard(
                              child: Row(children: [
                            SizedBox(
                                width: 54,
                                height: 54,
                                child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: CocktailCover(drink: drink))),
                            const SizedBox(width: 13),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(
                                    drink.nameFor(languageCode),
                                    style: languageCode == 'en'
                                        ? AppType.cocktailEnglish(size: 15)
                                        : AppType.serifZh(size: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('${drink.base} · ${drink.abv}% ABV',
                                      style: AppType.sans(
                                          size: 11.5,
                                          color: Colors.white
                                              .withValues(alpha: .5)))
                                ])),
                            Icon(PhosphorIcons.caretRight(),
                                color: Colors.white.withValues(alpha: .4),
                                size: 17)
                          ])))),
            ])));
  }
}
