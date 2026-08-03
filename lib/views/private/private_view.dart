import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../components/app_empty_view.dart';
import '../../components/app_loading_view.dart';
import '../../components/cocktail_cover.dart';
import '../../components/glass.dart';
import '../../components/horizontal_edge_shadow.dart';
import '../../components/palette.dart';
import '../../core/network/api_exception.dart';
import '../../core/navigation/root_tab_bar_composition.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/l10n.dart';
import '../../models/cocktail.dart';
import '../../stores/my_cocktails_store.dart';
import '../../stores/settings_store.dart';
import '../../stores/user_store.dart';

class PrivateView extends ConsumerStatefulWidget {
  const PrivateView({super.key});

  @override
  ConsumerState<PrivateView> createState() => _PrivateViewState();
}

class _PrivateViewState extends ConsumerState<PrivateView> {
  late final ScrollController _scrollController;
  final Map<String, String> _validationErrors = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_loadMoreIfNeeded);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(ambientColorProvider.notifier).state = const Color(0xFFBF5AF2);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMoreIfNeeded() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > 500) {
      return;
    }
    final status = ref.read(myCocktailStatusProvider);
    unawaited(ref.read(myCocktailsProvider(status).notifier).loadMore());
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final selectedStatus = ref.watch(myCocktailStatusProvider);
    final top = MediaQuery.paddingOf(context).top;

    if (!user.isLoggedIn) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          top + 20,
          AppSpacing.gutter,
          132,
        ),
        child: AppEmptyView(
          icon: PhosphorIcons.lockKey(),
          title: context.l10n.privateCocktails,
          subtitle: context.l10n.loginManageCocktails,
          actionLabel: context.l10n.login,
          onAction: () => context.push('/login'),
        ),
      );
    }

    final state = ref.watch(myCocktailsProvider(selectedStatus));
    ref.listen<MyCocktailsState>(myCocktailsProvider(selectedStatus),
        (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        final error = next.error;
        ref.read(toastProvider.notifier).show(
              error is ApiException
                  ? error.message
                  : context.l10n.cocktailActionFailed,
            );
      }
    });

    return RefreshIndicator.adaptive(
      onRefresh: () => ref
          .read(myCocktailsProvider(selectedStatus).notifier)
          .loadFirstPage(),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              top + 20,
              AppSpacing.gutter,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(context.l10n.privateCocktails,
                            style: AppType.serifZh(size: 28)),
                      ),
                      GlassCircleButton(
                        icon: PhosphorIcons.plus(PhosphorIconsStyle.bold),
                        appleSystemImageName: 'plus',
                        semanticLabel: context.l10n.uploadCocktail,
                        onTap: () => context.push('/upload?private=true'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.privateCocktailSubtitle(user.name),
                    style: AppType.sans(
                      size: 13,
                      color: Colors.white.withValues(alpha: .5),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 42,
                    child: HorizontalEdgeShadow(
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final status = _filters[index];
                          return GlassChip(
                            label: _statusLabel(context, status),
                            selected: selectedStatus == status,
                            onTap: () => ref
                                .read(myCocktailStatusProvider.notifier)
                                .state = status,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
          if (state.isLoading && state.items.isEmpty)
            const SliverFillRemaining(child: AppLoadingView())
          else if (state.items.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
              ),
              sliver: SliverToBoxAdapter(
                child: GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 26),
                    child: Column(
                      children: [
                        Icon(PhosphorIcons.bookOpen(),
                            color: Colors.white.withValues(alpha: .45),
                            size: 30),
                        const SizedBox(height: 12),
                        Text(context.l10n.privateCocktailEmpty,
                            style: AppType.serifZh(size: 17)),
                        const SizedBox(height: 6),
                        Text(
                          context.l10n.privateCocktailEmptyHint,
                          textAlign: TextAlign.center,
                          style: AppType.sans(
                            size: 12.5,
                            color: Colors.white.withValues(alpha: .45),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
              ),
              sliver: SliverList.separated(
                itemCount: state.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 11),
                itemBuilder: (context, index) => _cocktailCard(
                  context,
                  state.items[index],
                  state.busyIds.contains(state.items[index].id),
                ),
              ),
            ),
          if (state.isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 132)),
        ],
      ),
    );
  }

  Widget _cocktailCard(BuildContext context, Cocktail drink, bool busy) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final reason = drink.latestRevision?.rejectReason ??
        drink.rejectReason ??
        drink.offlineReason;
    return PressScale(
      onTap: () =>
          context.push('/detail/${drink.id}?editable=true', extra: drink),
      child: GlassCard(
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CocktailCover(drink: drink),
              ),
            ),
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
                  const SizedBox(height: 5),
                  Text(
                    drink.isPrivate
                        ? context.l10n.cocktailStatusPrivate
                        : _statusLabel(context, drink.status),
                    style: AppType.sans(
                      size: 11.5,
                      color: Colors.white.withValues(alpha: .58),
                    ),
                  ),
                  if (reason?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.reviewReason(reason!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.sans(
                        size: 11,
                        color: const Color(0xFFFF9F0A),
                      ),
                    ),
                  ],
                  if (_validationErrors[drink.id] != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _validationErrors[drink.id]!,
                      style: AppType.sans(
                        size: 12,
                        color: const Color(0xFFFF8A8A),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (busy)
              const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
                onPressed: () => _showActions(drink),
                icon: Icon(
                  PhosphorIcons.dotsThreeVertical(),
                  color: Colors.white.withValues(alpha: .6),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showActions(Cocktail drink) async {
    RootTabBarComposition.overlayDidPresent();
    _CocktailAction? action;
    try {
      // UIKit platform views composite above Flutter overlays. Give the root
      // tab bar one frame to leave the composition before presenting the
      // Cupertino action sheet, otherwise it can cover the sheet's bottom.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      action = await showCupertinoModalPopup<_CocktailAction>(
        context: context,
        builder: (sheetContext) => CupertinoActionSheet(
          actions: [
            if (drink.status != CocktailStatus.pending)
              CupertinoActionSheetAction(
                onPressed: () =>
                    Navigator.pop(sheetContext, _CocktailAction.edit),
                child: Text(context.l10n.editCocktail),
              ),
            if (!drink.isPrivate &&
                ({
                      CocktailStatus.draft,
                      CocktailStatus.rejected,
                      CocktailStatus.offline,
                    }.contains(drink.status) ||
                    (drink.status == CocktailStatus.published &&
                        {
                          CocktailStatus.draft,
                          CocktailStatus.rejected,
                        }.contains(drink.latestRevision?.status))))
              CupertinoActionSheetAction(
                onPressed: () =>
                    Navigator.pop(sheetContext, _CocktailAction.submit),
                child: Text(context.l10n.submitForReview),
              ),
            if (drink.status == CocktailStatus.pending ||
                drink.latestRevision?.status == CocktailStatus.pending)
              CupertinoActionSheetAction(
                onPressed: () =>
                    Navigator.pop(sheetContext, _CocktailAction.withdraw),
                child: Text(context.l10n.withdrawReview),
              ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () =>
                  Navigator.pop(sheetContext, _CocktailAction.delete),
              child: Text(context.l10n.deleteCocktail),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(sheetContext),
            child: Text(context.l10n.cancel),
          ),
        ),
      );
    } finally {
      RootTabBarComposition.overlayDidDismiss();
    }
    if (!mounted || action == null) return;
    final status = ref.read(myCocktailStatusProvider);
    final notifier = ref.read(myCocktailsProvider(status).notifier);
    try {
      switch (action) {
        case _CocktailAction.edit:
          await context.push('/upload?edit=${drink.id}', extra: drink);
          if (mounted) await notifier.loadFirstPage();
          break;
        case _CocktailAction.submit:
          final validationError = _submissionValidationError(drink);
          if (validationError != null) {
            if (mounted) {
              setState(() => _validationErrors[drink.id] = validationError);
            }
            break;
          }
          setState(() => _validationErrors.remove(drink.id));
          await notifier.submit(drink.id);
          if (mounted) {
            ref
                .read(toastProvider.notifier)
                .show(context.l10n.cocktailSubmitted);
          }
          break;
        case _CocktailAction.withdraw:
          await notifier.withdraw(drink.id);
          if (mounted) {
            ref
                .read(toastProvider.notifier)
                .show(context.l10n.cocktailWithdrawn);
          }
          break;
        case _CocktailAction.delete:
          if (!await _confirmDelete()) return;
          await notifier.remove(drink.id);
          if (mounted) {
            ref.read(toastProvider.notifier).show(context.l10n.cocktailDeleted);
          }
          break;
      }
    } catch (_) {
      if (mounted) {
        ref
            .read(toastProvider.notifier)
            .show(context.l10n.cocktailActionFailed);
      }
    }
  }

  String? _submissionValidationError(Cocktail drink) {
    if (drink.zh.trim().isEmpty && drink.en.trim().isEmpty) {
      return context.l10n.enterChineseName;
    }
    if (drink.spirit?.trim().isEmpty != false ||
        drink.recipe.every((item) => item.n.trim().isEmpty)) {
      return context.l10n.validationRecipeRequired;
    }
    if (drink.isPrivate) {
      return context.l10n.validationPrivateSubmit;
    }
    return null;
  }

  Future<bool> _confirmDelete() async {
    return await showCupertinoDialog<bool>(
          context: context,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: Text(context.l10n.deleteCocktailTitle),
            content: Text(context.l10n.deleteCocktailBody),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(context.l10n.cancel),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(context.l10n.deleteCocktail),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _statusLabel(BuildContext context, CocktailStatus? status) {
    return switch (status) {
      null => context.l10n.cocktailStatusAll,
      CocktailStatus.draft => context.l10n.cocktailStatusDraft,
      CocktailStatus.pending => context.l10n.cocktailStatusPending,
      CocktailStatus.rejected => context.l10n.cocktailStatusRejected,
      CocktailStatus.published => context.l10n.cocktailStatusPublished,
      CocktailStatus.offline => context.l10n.cocktailStatusOffline,
    };
  }
}

const _filters = <CocktailStatus?>[
  null,
  CocktailStatus.draft,
  CocktailStatus.pending,
  CocktailStatus.rejected,
  CocktailStatus.published,
  CocktailStatus.offline,
];

enum _CocktailAction { edit, submit, withdraw, delete }
