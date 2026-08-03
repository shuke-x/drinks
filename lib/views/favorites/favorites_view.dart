import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../components/app_loading_view.dart';
import '../../components/cocktail_cover.dart';
import '../../components/frosted_page_overlay.dart';
import '../../components/glass.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../stores/cocktail_store.dart';
import '../../stores/settings_store.dart';
import '../../stores/user_store.dart';
import '../../l10n/l10n.dart';

class FavoritesView extends ConsumerWidget {
  const FavoritesView({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      return Scaffold(
          backgroundColor: const Color(0xB80D0B10),
          body: const AppLoadingView());
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
                              color: Colors.white.withOpacity(.45), size: 30),
                          const SizedBox(height: 12),
                          Text(context.l10n.noFavorites,
                              style: AppType.serifZh(size: 17)),
                          const SizedBox(height: 5),
                          Text(context.l10n.favoriteEmptyHint,
                              style: AppType.sans(
                                  size: 12.5,
                                  color: Colors.white.withOpacity(.45)))
                        ]))),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(
                                  drink.nameFor(languageCode),
                                  style: languageCode == 'en'
                                      ? AppType.cocktailEnglish(size: 17)
                                      : AppType.serifZh(size: 16),
                                ),
                                const SizedBox(height: 4),
                                Text('${drink.base} · ${drink.abv}% ABV',
                                    style: AppType.sans(
                                        size: 11.5,
                                        color: Colors.white.withOpacity(.5)))
                              ])),
                          Icon(PhosphorIcons.caretRight(),
                              color: Colors.white.withOpacity(.4), size: 17)
                        ])))),
            ])));
  }
}
