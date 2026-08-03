import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/query/query_cache.dart';
import '../data/apis/api_providers.dart';
import '../data/apis/cocktail_api.dart';
import '../data/apis/user_api.dart';
import '../models/cocktail.dart';

class MyCocktailsState {
  const MyCocktailsState({
    this.items = const [],
    this.page = 0,
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.busyIds = const {},
    this.error,
  });

  final List<Cocktail> items;
  final int page;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final Set<String> busyIds;
  final Object? error;

  bool get hasMore => page == 0 || items.length < total;

  MyCocktailsState copyWith({
    List<Cocktail>? items,
    int? page,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    Set<String>? busyIds,
    Object? error,
    bool clearError = false,
  }) =>
      MyCocktailsState(
        items: items ?? this.items,
        page: page ?? this.page,
        total: total ?? this.total,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        busyIds: busyIds ?? this.busyIds,
        error: clearError ? null : error ?? this.error,
      );
}

class MyCocktailsNotifier extends CachedQueryNotifier<MyCocktailsState> {
  MyCocktailsNotifier(
    this._userApi,
    this._cocktailApi,
    this._status,
    MyCocktailsState initialState,
    QueryClient queryClient,
    QueryKey queryKey,
  ) : super(
          initialState,
          queryClient: queryClient,
          queryKey: queryKey,
        );

  static const pageSize = 20;
  final UserApi _userApi;
  final CocktailApi _cocktailApi;
  final CocktailStatus? _status;

  @override
  Future<void> loadFirstPage() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final nextState = await queryClient.fetchQuery<MyCocktailsState>(
        key: queryKey,
        force: true,
        queryFn: () async {
          final result = await _userApi.myCocktailsPage(
            page: 1,
            limit: pageSize,
            status: _status,
          );
          return MyCocktailsState(
            items: List.unmodifiable(result.items),
            page: result.page,
            total: result.total,
          );
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
      final result = await _userApi.myCocktailsPage(
        page: state.page + 1,
        limit: pageSize,
        status: _status,
      );
      final byId = <String, Cocktail>{
        for (final item in state.items) item.id: item,
        for (final item in result.items) item.id: item,
      };
      state = MyCocktailsState(
        items: List.unmodifiable(byId.values),
        page: result.page,
        total: result.total,
      );
      cacheCurrentState();
    } catch (error) {
      state = state.copyWith(isLoadingMore: false, error: error);
    }
  }

  Future<void> submit(String id) => _mutate(id, _cocktailApi.submit);

  Future<void> withdraw(String id) => _mutate(id, _cocktailApi.withdraw);

  Future<void> _mutate(
    String id,
    Future<Cocktail> Function(String id) operation,
  ) async {
    if (state.busyIds.contains(id)) return;
    state = state.copyWith(busyIds: {...state.busyIds, id});
    try {
      final updated = await operation(id);
      if (_status != null && updated.status != _status) {
        state = state.copyWith(
          items: state.items.where((item) => item.id != id).toList(),
          total: state.total > 0 ? state.total - 1 : 0,
          busyIds: {...state.busyIds}..remove(id),
        );
      } else {
        state = state.copyWith(
          items: [
            for (final item in state.items)
              if (item.id == id) updated else item,
          ],
          busyIds: {...state.busyIds}..remove(id),
        );
      }
      queryClient.invalidateQueries(myCocktailsQueryPrefix);
      cacheCurrentState();
    } catch (error) {
      state = state.copyWith(
        busyIds: {...state.busyIds}..remove(id),
        error: error,
      );
      rethrow;
    }
  }

  Future<void> remove(String id) async {
    if (state.busyIds.contains(id)) return;
    state = state.copyWith(busyIds: {...state.busyIds, id});
    try {
      await _cocktailApi.delete(id);
      state = state.copyWith(
        items: state.items.where((item) => item.id != id).toList(),
        total: state.total > 0 ? state.total - 1 : 0,
        busyIds: {...state.busyIds}..remove(id),
      );
      queryClient.invalidateQueries(myCocktailsQueryPrefix);
      cacheCurrentState();
    } catch (error) {
      state = state.copyWith(
        busyIds: {...state.busyIds}..remove(id),
        error: error,
      );
      rethrow;
    }
  }
}

final myCocktailStatusProvider = StateProvider<CocktailStatus?>((ref) => null);

const myCocktailsQueryPrefix = QueryKey(['my-cocktails']);

QueryKey myCocktailsQueryKey(CocktailStatus? status) =>
    QueryKey(['my-cocktails', status?.name]);

final myCocktailsProvider = StateNotifierProvider.autoDispose
    .family<MyCocktailsNotifier, MyCocktailsState, CocktailStatus?>(
        (ref, status) {
  final queryClient = ref.watch(queryClientProvider);
  final policy = ref.watch(queryCachePolicyProvider);
  final queryKey = myCocktailsQueryKey(status);
  final initialState = queryClient.registerQuery(
    queryKey,
    const MyCocktailsState(),
  );
  final notifier = MyCocktailsNotifier(
    ref.watch(userApiProvider),
    ref.watch(cocktailApiProvider),
    status,
    initialState,
    queryClient,
    queryKey,
  );
  attachQueryCache(ref, notifier, policy);
  notifier.refetchIfStale(policy.staleTime);
  return notifier;
});
