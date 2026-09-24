import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../components/ambient_background.dart';
import '../../components/app_empty_view.dart';
import '../../components/app_loading_view.dart';
import '../../components/common/common.dart';
import '../../components/glass.dart' show RiseIn;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_effects.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/l10n.dart';
import '../../models/cocktail.dart';
import '../../stores/cocktail_store.dart';
import '../home/widgets/waterfall_card.dart';

class SearchView extends ConsumerStatefulWidget {
  const SearchView({super.key, this.selectRecipe = false});
  final bool selectRecipe;

  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView>
    with SingleTickerProviderStateMixin {
  static const _searchControlDuration = Duration(milliseconds: 420);

  final _queryController = TextEditingController();
  final _focusNode = FocusNode();
  late final AnimationController _searchActivationController;
  late final Animation<double> _searchActivation;
  String _query = '';
  bool _isSearchActive = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _searchActivationController = AnimationController(
      vsync: this,
      duration: _searchControlDuration,
      reverseDuration: _searchControlDuration,
    );
    _searchActivation = CurvedAnimation(
      parent: _searchActivationController,
      curve: AppMotion.overlayEnter,
      reverseCurve: AppMotion.overlayExit,
    );
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion && !_reduceMotion) {
      _searchActivationController.value = _isSearchActive ? 1 : 0;
    }
    _reduceMotion = reduceMotion;
  }

  void _handleFocusChanged() {
    if (!mounted || !_focusNode.hasFocus || _isSearchActive) return;
    _setSearchActive(true);
  }

  void _setSearchActive(bool active) {
    if (_isSearchActive == active) return;
    setState(() => _isSearchActive = active);
    if (_reduceMotion) {
      _searchActivationController.value = active ? 1 : 0;
      return;
    }
    if (active) {
      _searchActivationController.forward();
    } else {
      _searchActivationController.reverse();
    }
  }

  void _closeSearch() {
    _queryController.clear();
    _focusNode.unfocus();
    if (_query.isNotEmpty) setState(() => _query = '');
    _setSearchActive(false);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _searchActivationController.dispose();
    _queryController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final builtin = ref.watch(builtinDrinksProvider);
    final all = ref.watch(allDrinksProvider);
    final results = _filter(all, _query);
    final topPadding = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AmbientBackground(color: AppColors.systemAccent),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                AnimatedBuilder(
                  key: const ValueKey('search_header_collapse'),
                  animation: _searchActivation,
                  child: RiseIn(
                    key: const ValueKey('search_header_rise'),
                    followRouteOnExit: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.gutter,
                        topPadding > 0 ? 8 : 16,
                        AppSpacing.gutter,
                        16,
                      ),
                      child: Row(
                        children: [
                          GlassCircleButton(
                            key: const ValueKey('search_back'),
                            icon: PhosphorIcons.arrowLeft(
                              PhosphorIconsStyle.bold,
                            ),
                            appleSystemImageName: 'chevron.left',
                            size: 44,
                            iconSize: 16,
                            semanticLabel: MaterialLocalizations.of(context)
                                .backButtonTooltip,
                            onTap: () => context.pop(),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              context.l10n.searchCocktails,
                              style: AppType.serifZh(size: 25, height: 1.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  builder: (context, child) {
                    final progress = _searchActivation.value;
                    final visibility = 1 - progress;
                    final opacity = (1 - (progress / .62)).clamp(0.0, 1.0);
                    return ClipRect(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        heightFactor: visibility,
                        child: IgnorePointer(
                          ignoring: _isSearchActive,
                          child: Opacity(
                            key: const ValueKey('search_header_opacity'),
                            opacity: opacity,
                            child: Transform.translate(
                              offset: Offset(0, -12 * progress),
                              child: child,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                RiseIn(
                  key: const ValueKey('search_field_rise'),
                  delay: const Duration(milliseconds: 80),
                  followRouteOnExit: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.gutter,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoSearchTextField(
                            key: const ValueKey('cocktail_search_field'),
                            controller: _queryController,
                            focusNode: _focusNode,
                            placeholder: context.l10n.searchCocktailsHint,
                            borderRadius: BorderRadius.circular(18),
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              12,
                              13,
                              12,
                              13,
                            ),
                            prefixInsets: const EdgeInsetsDirectional.fromSTEB(
                              14,
                              0,
                              8,
                              0,
                            ),
                            suffixInsets: const EdgeInsetsDirectional.fromSTEB(
                              8,
                              0,
                              14,
                              0,
                            ),
                            prefixIcon: Icon(
                              PhosphorIcons.magnifyingGlass(
                                PhosphorIconsStyle.bold,
                              ),
                              size: 20,
                            ),
                            suffixIcon: Icon(
                              PhosphorIcons.xCircle(PhosphorIconsStyle.fill),
                              size: 20,
                            ),
                            suffixMode: OverlayVisibilityMode.editing,
                            style: AppType.sans(
                              size: 16,
                              color: Colors.white,
                            ),
                            placeholderStyle: AppType.sans(
                              size: 15,
                              color: Colors.white.withValues(alpha: .42),
                            ),
                            backgroundColor:
                                Colors.white.withValues(alpha: .10),
                            itemColor: Colors.white.withValues(alpha: .62),
                            onChanged: (value) =>
                                setState(() => _query = value),
                          ),
                        ),
                        AnimatedBuilder(
                          key: const ValueKey('search_close_reveal'),
                          animation: _searchActivation,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: GlassCircleButton(
                              key: const ValueKey('search_close_action'),
                              icon: PhosphorIcons.x(
                                PhosphorIconsStyle.bold,
                              ),
                              appleSystemImageName: 'xmark',
                              size: 44,
                              iconSize: 16,
                              backgroundColor:
                                  Colors.white.withValues(alpha: .16),
                              semanticLabel: context.l10n.close,
                              onTap: _closeSearch,
                            ),
                          ),
                          builder: (context, child) {
                            final progress = _searchActivation.value;
                            return SizedBox(
                              width: 54 * progress,
                              height: 44,
                              child: ClipRect(
                                child: OverflowBox(
                                  alignment: Alignment.centerRight,
                                  minWidth: 54,
                                  maxWidth: 54,
                                  child: IgnorePointer(
                                    ignoring: !_isSearchActive,
                                    child: ExcludeSemantics(
                                      excluding: !_isSearchActive,
                                      child: Opacity(
                                        key: const ValueKey(
                                          'search_close_opacity',
                                        ),
                                        opacity: progress,
                                        child: Transform.translate(
                                          key: const ValueKey(
                                            'search_close_slide',
                                          ),
                                          offset: Offset(
                                            14 * (1 - progress),
                                            0,
                                          ),
                                          child: child,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: RiseIn(
                    key: const ValueKey('search_results_rise'),
                    delay: const Duration(milliseconds: 160),
                    followRouteOnExit: false,
                    child: builtin.isLoading && all.isEmpty
                        ? const AppLoadingView(
                            themeColor: AppColors.systemAccent,
                          )
                        : results.isEmpty
                            ? AppEmptyView(
                                icon: PhosphorIcons.magnifyingGlass(),
                                title: context.l10n.searchNoResults,
                                subtitle: context.l10n.searchNoResultsHint,
                              )
                            : MasonryGridView.count(
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.gutter,
                                  0,
                                  AppSpacing.gutter,
                                  40,
                                ),
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                itemCount: results.length,
                                itemBuilder: (context, index) {
                                  final drink = results[index];
                                  return WaterfallCard(
                                    key: ValueKey('search_${drink.id}'),
                                    drink: drink,
                                    coverHeight: const [
                                      132.0,
                                      168.0,
                                      150.0,
                                      186.0,
                                    ][index % 4],
                                    onTap: () => widget.selectRecipe
                                        ? context.pop(drink)
                                        : context.push(
                                            '/detail/${drink.id}',
                                            extra: drink,
                                          ),
                                  );
                                },
                              ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Cocktail> _filter(List<Cocktail> drinks, String rawQuery) {
    final query = rawQuery.trim().toLowerCase();
    final unique = <String, Cocktail>{
      for (final drink in drinks) drink.id: drink,
    }.values;
    if (query.isEmpty) return unique.toList(growable: false);
    return unique.where((drink) {
      final searchable = <String>[
        drink.zh,
        drink.en,
        if (drink.spirit != null) drink.spirit!,
        drink.base,
        ...drink.tags,
        ...drink.recipe.map((item) => item.n),
      ].join('\n').toLowerCase();
      return searchable.contains(query);
    }).toList(growable: false);
  }
}
