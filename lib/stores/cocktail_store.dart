import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/cocktail_repository.dart';
import '../core/network/api_page.dart';
import '../core/query/query_cache.dart';
import '../models/cocktail.dart';
import 'settings_store.dart';

/// 仓库单例（测试时可 override 注入 fake）。
final cocktailRepositoryProvider = Provider<CocktailRepository>((ref) {
  return CocktailRepository();
});

/// 内置/官方酒单。
final builtinDrinksProvider = FutureProvider<List<Cocktail>>((ref) async {
  final drinks = await ref.watch(cocktailRepositoryProvider).getAll();
  debugPrint('[CocktailStore] list (${drinks.length})\n'
      '${const JsonEncoder.withIndent('  ').convert(drinks.map((e) => e.toJson()).toList())}');
  return drinks;
});

/// 今日推荐（Home 轮播，原型取前 4 款）。
final recommendationsProvider = FutureProvider<List<Cocktail>>((ref) async {
  final drinks =
      await ref.watch(cocktailRepositoryProvider).getRecommendations();
  debugPrint('[CocktailStore] recommendations (${drinks.length})\n'
      '${const JsonEncoder.withIndent('  ').convert(drinks.map((e) => e.toJson()).toList())}');
  return drinks;
});

/// 首页分类列表。分类 code 直接传给服务端 `GET /cocktails?spirit=...`。
final homeDrinksProvider =
    FutureProvider.family<List<Cocktail>, String?>((ref, spirit) async {
  final repository = ref.watch(cocktailRepositoryProvider);
  if (spirit == null) return ref.watch(builtinDrinksProvider.future);
  return repository.getBySpirit(spirit);
});

class CocktailFeedState {
  const CocktailFeedState({
    this.items = const [],
    this.page = 0,
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  final List<Cocktail> items;
  final int page;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final Object? error;

  bool get hasMore => items.length < total || page == 0;

  CocktailFeedState copyWith({
    List<Cocktail>? items,
    int? page,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error,
    bool clearError = false,
  }) =>
      CocktailFeedState(
        items: items ?? this.items,
        page: page ?? this.page,
        total: total ?? this.total,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error: clearError ? null : error ?? this.error,
      );
}

class CocktailFeedNotifier extends CachedQueryNotifier<CocktailFeedState> {
  CocktailFeedNotifier(
    this._repository,
    this._spirit,
    CocktailFeedState initialState,
    QueryClient queryClient,
    QueryKey queryKey,
  ) : super(
          initialState,
          queryClient: queryClient,
          queryKey: queryKey,
        );

  static const pageSize = 20;
  final CocktailRepository _repository;
  final String? _spirit;

  @override
  Future<void> loadFirstPage() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final nextState = await queryClient.fetchQuery<CocktailFeedState>(
        key: queryKey,
        force: true,
        queryFn: () async {
          final result = await _repository.getPage(
            spirit: _spirit,
            page: 1,
            limit: pageSize,
          );
          return _fromPage(result, isLoading: false);
        },
      );
      if (!mounted) return;
      state = nextState;
    } catch (error) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: error);
      }
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final result = await _repository.getPage(
        spirit: _spirit,
        page: state.page + 1,
        limit: pageSize,
      );
      final byId = <String, Cocktail>{
        for (final item in state.items) item.id: item,
        for (final item in result.items) item.id: item,
      };
      state = CocktailFeedState(
        items: List.unmodifiable(byId.values),
        page: result.page,
        total: result.total,
      );
      cacheCurrentState();
    } catch (error) {
      state = state.copyWith(isLoadingMore: false, error: error);
    }
  }

  CocktailFeedState _fromPage(
    ApiPage<Cocktail> result, {
    required bool isLoading,
  }) =>
      CocktailFeedState(
        items: List.unmodifiable(result.items),
        page: result.page,
        total: result.total,
        isLoading: isLoading,
      );
}

const cocktailFeedQueryPrefix = QueryKey(['cocktail-feed']);

QueryKey cocktailFeedQueryKey(String? spirit) =>
    QueryKey(['cocktail-feed', spirit]);

final cocktailFeedProvider = StateNotifierProvider.autoDispose
    .family<CocktailFeedNotifier, CocktailFeedState, String?>((ref, spirit) {
  final queryClient = ref.watch(queryClientProvider);
  final policy = ref.watch(queryCachePolicyProvider);
  final queryKey = cocktailFeedQueryKey(spirit);
  final initialState = queryClient.registerQuery(
    queryKey,
    const CocktailFeedState(),
  );
  final notifier = CocktailFeedNotifier(
    ref.watch(cocktailRepositoryProvider),
    spirit,
    initialState,
    queryClient,
    queryKey,
  );
  attachQueryCache(ref, notifier, policy);
  notifier.refetchIfStale(policy.staleTime);

  return notifier;
});

final cocktailDetailProvider =
    FutureProvider.autoDispose.family<Cocktail?, String>((ref, id) {
  return ref.watch(cocktailRepositoryProvider).getDetail(id);
});

/// 全部酒 = 内置 + 我的酒单（原型 all()）。
final allDrinksProvider = Provider<List<Cocktail>>((ref) {
  final builtin =
      ref.watch(builtinDrinksProvider).valueOrNull ?? const <Cocktail>[];
  final mine = ref.watch(appDataProvider).mine;
  return [...builtin, ...mine];
});

/// 按 id 查找（原型 find()）。
final drinkByIdProvider = Provider.family<Cocktail?, String>((ref, id) {
  final all = ref.watch(allDrinksProvider);
  for (final d in all) {
    if (d.id == id) {
      debugPrint('[CocktailStore] detail $id\n'
          '${const JsonEncoder.withIndent('  ').convert(d.toJson())}');
      return d;
    }
  }
  debugPrint('[CocktailStore] detail $id: not found');
  return null;
});

/// Home 当前分类。
final homeCategoryProvider = StateProvider<String?>((ref) => null);
