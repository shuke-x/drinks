import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../components/glass.dart';
import '../../components/cocktail_cover.dart';
import '../../components/app_loading_view.dart';
import '../../components/frosted_page_overlay.dart';
import '../../components/palette.dart';
import '../../core/interaction/app_feedback.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/network/api_exception.dart';
import '../../core/query/query_cache.dart';
import '../../data/apis/api_providers.dart';
import '../../models/cocktail.dart';
import '../../stores/cocktail_store.dart';
import '../../stores/deck_store.dart';
import '../../stores/my_cocktails_store.dart';
import '../../stores/settings_store.dart';
import '../../stores/user_store.dart';
import '../../l10n/l10n.dart';

/// 详情覆盖层 —— 原型 detail：
/// 全屏 rgba(13,11,16,.72)+blur(26) 覆盖，330 高渐变头图 + 光球 + 玻璃环，
/// 内容卡片以 riseIn 交错入场（延迟每层 +0.08s）。
class DetailView extends ConsumerStatefulWidget {
  const DetailView({
    super.key,
    required this.id,
    this.initialDrink,
    this.allowEditing = false,
  });

  final String id;
  final Cocktail? initialDrink;
  final bool allowEditing;

  @override
  ConsumerState<DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends ConsumerState<DetailView> {
  Color? _prevAmbient;
  late final StateController<Color> _ambientController;
  late final DeckController _deckController;
  bool _closingUnavailableDetail = false;

  @override
  void initState() {
    super.initState();
    _ambientController = ref.read(ambientColorProvider.notifier);
    _deckController = ref.read(deckControllerProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final drink =
          ref.read(drinkByIdProvider(widget.id)) ?? widget.initialDrink;
      if (drink != null) {
        _prevAmbient = ref.read(ambientColorProvider);
        _ambientController.state = drink.themeColor;
      }
      // 原型：详情打开时卡组巡航暂停
      _deckController.pause();
    });
  }

  @override
  void dispose() {
    // 路由卸载与父级重建可能发生在同一帧。Riverpod 禁止在 dispose
    // 期间同步通知，因此把两个全局状态恢复动作统一移到当前构建帧之后。
    final previousAmbient = _prevAmbient;
    Future<void>(() {
      if (previousAmbient != null) {
        _ambientController.state = previousAmbient;
      }
      _deckController.resume();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cached =
        ref.watch(drinkByIdProvider(widget.id)) ?? widget.initialDrink;
    final detail = ref.watch(cocktailDetailProvider(widget.id));
    final drink = detail.valueOrNull ?? cached;
    final unit = ref.watch(appDataProvider).unit;
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final ambient = ref.watch(ambientColorProvider);
    final user = ref.watch(userProvider);
    ref.listen<AsyncValue<Cocktail?>>(cocktailDetailProvider(widget.id),
        (previous, next) {
      final remote = next.valueOrNull;
      if (remote == null || remote.themeColor == _ambientController.state) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ambientController.state = remote.themeColor;
      });
    });

    if (drink == null) {
      if (detail.isLoading) {
        return Scaffold(
          backgroundColor: const Color(0xB80D0B10),
          body: AppLoadingView(themeColor: ambient),
        );
      }
      if (!_closingUnavailableDetail) {
        _closingUnavailableDetail = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(toastProvider.notifier).show(detail.hasError
              ? context.l10n.loadFailedDescription
              : context.l10n.cocktailNotFound);
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        });
      }
      return const SizedBox.expand();
    }

    final c = drink.themeColor;
    final languageCode = Localizations.localeOf(context).languageCode;
    final primaryName = drink.nameFor(languageCode);
    final alternateName = drink.alternateNameFor(languageCode);
    final chips = <String>[drink.base, '${drink.abv}% ABV', ...drink.tags];
    final canEdit = user.isLoggedIn &&
        (widget.allowEditing || drink.isOwnedBy(user.id)) &&
        drink.status != CocktailStatus.pending;
    final canDeleteDraft = canEdit && drink.status == CocktailStatus.draft;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FrostedPageOverlay(
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // ---- 头图 ----
            SizedBox(
              // Artwork is full-bleed behind the status bar. Only the
              // interactive controls are inset below the sensor housing.
              height: 330 + topPad,
              child: Stack(children: [
                Positioned.fill(
                  child: CocktailCover(drink: drink),
                ),
                // 大光球
                if (drink.images.isEmpty)
                  Align(
                    alignment: const Alignment(0, .1),
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: drinkOrb(c),
                      ),
                    ),
                  ),
                // 玻璃圆环与默认圆球成组展示；有封面图片时不叠加。
                if (drink.images.isEmpty)
                  Align(
                    alignment: const Alignment(0, .1),
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(.3)),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(.24),
                            Colors.white.withOpacity(.05),
                          ],
                        ),
                      ),
                    ),
                  ),
                // 底部渐隐到基底
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 120,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          const Color(0xFF0D0B10).withOpacity(.9),
                          const Color(0xFF0D0B10).withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  top: topPad + 8,
                  child: GlassCircleButton(
                    icon: user.favoriteIds.contains(drink.id)
                        ? PhosphorIcons.heart(PhosphorIconsStyle.fill)
                        : PhosphorIcons.heart(),
                    appleSystemImageName: user.favoriteIds.contains(drink.id)
                        ? 'heart.fill'
                        : 'heart',
                    size: 38,
                    iconSize: 17,
                    iconColor: user.favoriteIds.contains(drink.id)
                        ? AppColors.danger
                        : Colors.white,
                    semanticLabel: user.favoriteIds.contains(drink.id)
                        ? context.l10n.removeFromFavorites
                        : context.l10n.addToFavorites,
                    onTap: () async {
                      final l10n = context.l10n;
                      if (!user.isLoggedIn) {
                        ref
                            .read(toastProvider.notifier)
                            .show(l10n.loginToFavorite);
                        context.push('/login');
                        return;
                      }
                      try {
                        final saved = await ref
                            .read(userProvider.notifier)
                            .toggleFavorite(drink.id);
                        if (!mounted) return;
                        AppFeedback.success();
                        ref.read(toastProvider.notifier).show(
                            saved ? l10n.favoriteAdded : l10n.favoriteRemoved);
                      } on ApiException catch (error) {
                        if (mounted) {
                          ref.read(toastProvider.notifier).show(error.message);
                        }
                      } catch (_) {
                        if (mounted) {
                          ref
                              .read(toastProvider.notifier)
                              .show(l10n.favoriteSyncFailed);
                        }
                      }
                    },
                  ),
                ),
                // 返回按钮
                Positioned(
                  left: 16,
                  top: topPad + 8,
                  child: GlassCircleButton(
                    key: const ValueKey('detail_back'),
                    icon: PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
                    appleSystemImageName: 'chevron.left',
                    size: 38,
                    iconSize: 16,
                    iconColor: Colors.white,
                    semanticLabel:
                        MaterialLocalizations.of(context).backButtonTooltip,
                    onTap: () => context.pop(),
                  ),
                ),
              ]),
            ),

            // ---- 内容（上移 52 叠在头图渐隐区上）----
            Transform.translate(
              offset: const Offset(0, -52),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter, 0, AppSpacing.gutter, 0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RiseIn(
                        followRouteOnExit: false,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                primaryName,
                                style: languageCode == 'en'
                                    ? AppType.cocktailEnglish(
                                        size: 34, height: 1.1)
                                    : AppType.serifZh(size: 32, height: 1.15),
                              ),
                              if (alternateName != null) ...[
                                const SizedBox(height: 7),
                                Text(
                                  alternateName,
                                  style: languageCode == 'en'
                                      ? AppType.serifZh(
                                          size: 14,
                                          weight: FontWeight.w500,
                                          color: Colors.white.withOpacity(.6),
                                        )
                                      : AppType.cocktailEnglish(
                                          size: 15,
                                          color: Colors.white.withOpacity(.65),
                                        ),
                                ),
                              ],
                              const SizedBox(height: 13),
                              Wrap(spacing: 7, runSpacing: 7, children: [
                                for (final t in chips)
                                  InfoPill(
                                    label: t,
                                    fontSize: 11,
                                    fill: Colors.white.withOpacity(.1),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 7),
                                  ),
                              ]),
                            ]),
                      ),
                      const SizedBox(height: 18),

                      // 配方
                      RiseIn(
                        delay: const Duration(milliseconds: 80),
                        followRouteOnExit: false,
                        child: GlassCard(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    context.l10n.recipeUnit(unit == 'oz'
                                        ? context.l10n.ounces
                                        : context.l10n.milliliters),
                                    style: AppType.eyebrow()),
                                const SizedBox(height: 5),
                                for (final r in drink.recipe)
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 9),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                            color:
                                                Colors.white.withOpacity(.07)),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(r.n,
                                            style: AppType.sans(
                                                size: 14.5,
                                                weight: FontWeight.w500,
                                                height: 1.3)),
                                        Text(formatAmount(r, unit),
                                            style: AppType.mono(
                                                size: 13,
                                                weight: FontWeight.w400,
                                                color: Colors.white
                                                    .withOpacity(.62))),
                                      ],
                                    ),
                                  ),
                              ]),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 调制步骤
                      RiseIn(
                        delay: const Duration(milliseconds: 160),
                        followRouteOnExit: false,
                        child: GlassCard(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(context.l10n.method,
                                    style: AppType.eyebrow()),
                                const SizedBox(height: 14),
                                for (var i = 0; i < drink.steps.length; i++)
                                  Padding(
                                    padding: EdgeInsets.only(
                                        bottom: i == drink.steps.length - 1
                                            ? 0
                                            : 13),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 23,
                                          height: 23,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color:
                                                Colors.white.withOpacity(.92),
                                          ),
                                          child: Text('${i + 1}',
                                              style: AppType.mono(
                                                  size: 11,
                                                  color:
                                                      const Color(0xFF0D0B10))),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(drink.steps[i],
                                              style: AppType.sans(
                                                  size: 14,
                                                  color: Colors.white
                                                      .withOpacity(.86),
                                                  height: 1.55)),
                                        ),
                                      ],
                                    ),
                                  ),
                              ]),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 杯具 / 装饰
                      Row(children: [
                        Expanded(
                          child: RiseIn(
                            delay: const Duration(milliseconds: 240),
                            followRouteOnExit: false,
                            child: _miniCard(PhosphorIcons.martini(),
                                context.l10n.glassware, drink.glass),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RiseIn(
                            delay: const Duration(milliseconds: 300),
                            followRouteOnExit: false,
                            child: _miniCard(PhosphorIcons.leaf(),
                                context.l10n.garnish, drink.garnish),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 14),

                      // 风味故事
                      RiseIn(
                        delay: const Duration(milliseconds: 380),
                        followRouteOnExit: false,
                        child: GlassCard(
                          fillOpacity: .07,
                          borderOpacity: .14,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(context.l10n.flavorStory,
                                    style: AppType.eyebrow()),
                                const SizedBox(height: 12),
                                Text(drink.story,
                                    style: AppType.playfair(
                                        size: 17,
                                        color: Colors.white.withOpacity(.9),
                                        height: 1.6)),
                              ]),
                        ),
                      ),
                      if (canEdit) ...[
                        const SizedBox(height: 22),
                        RiseIn(
                          delay: const Duration(milliseconds: 440),
                          followRouteOnExit: false,
                          child: SizedBox(
                            width: double.infinity,
                            child: GlassActionButton(
                              key: const ValueKey('detail_edit_cocktail'),
                              label: context.l10n.editCocktail,
                              fontSize: 14,
                              backgroundColor: const Color(0xFFE9EDF2),
                              onTap: () => _editCocktail(drink),
                            ),
                          ),
                        ),
                        if (canDeleteDraft) ...[
                          const SizedBox(height: 10),
                          RiseIn(
                            delay: const Duration(milliseconds: 500),
                            followRouteOnExit: false,
                            child: SizedBox(
                              width: double.infinity,
                              child: GlassActionButton(
                                key: const ValueKey('detail_delete_draft'),
                                label: context.l10n.deleteDraft,
                                fontSize: 13,
                                danger: true,
                                backgroundColor: const Color(0xFFFF6875),
                                onTap: () => _deleteDraft(drink),
                              ),
                            ),
                          ),
                        ],
                      ],
                      SizedBox(height: bottomPad + 28),
                    ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _editCocktail(Cocktail drink) async {
    await context.push('/upload?edit=${drink.id}', extra: drink);
    if (!mounted) return;
    final queryClient = ref.read(queryClientProvider);
    queryClient
      ..invalidateQueries(cocktailFeedQueryPrefix)
      ..invalidateQueries(myCocktailsQueryPrefix);
    ref.invalidate(cocktailDetailProvider(widget.id));
    ref.invalidate(cocktailFeedProvider);
    ref.invalidate(myCocktailsProvider);
  }

  Future<void> _deleteDraft(Cocktail drink) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(context.l10n.deleteDraftTitle),
        content: Text(context.l10n.deleteDraftBody),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.deleteDraft),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(cocktailApiProvider).delete(drink.id);
      final queryClient = ref.read(queryClientProvider);
      queryClient.invalidateQueries(myCocktailsQueryPrefix);
      ref.invalidate(myCocktailsProvider);
      if (mounted) {
        ref.read(toastProvider.notifier).show(context.l10n.cocktailDeleted);
        context.pop();
      }
    } on ApiException catch (error) {
      if (mounted) ref.read(toastProvider.notifier).show(error.message);
    } catch (_) {
      if (mounted) {
        ref
            .read(toastProvider.notifier)
            .show(context.l10n.cocktailActionFailed);
      }
    }
  }

  Widget _miniCard(IconData icon, String label, String value) {
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(16),
      shadow: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 19, color: Colors.white.withOpacity(.55)),
        const SizedBox(height: 11),
        Text(label.toUpperCase(),
            style: AppType.eyebrow(
                size: 11, tracking: .12, color: AppColors.text42)),
        const SizedBox(height: 6),
        Text(value,
            style: AppType.serifZh(
                size: 15, weight: FontWeight.w500, height: 1.3)),
      ]),
    );
  }
}
