import 'dart:async';
import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class QueryKey {
  const QueryKey(this.parts);

  final List<Object?> parts;

  bool startsWith(QueryKey prefix) {
    if (prefix.parts.length > parts.length) return false;
    for (var index = 0; index < prefix.parts.length; index++) {
      if (parts[index] != prefix.parts[index]) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) {
    if (other is! QueryKey || other.parts.length != parts.length) return false;
    for (var index = 0; index < parts.length; index++) {
      if (parts[index] != other.parts[index]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(parts);

  @override
  String toString() => 'QueryKey($parts)';
}

class QueryCacheEntry<T> {
  QueryCacheEntry({
    required this.data,
    required this.updatedAt,
    this.invalidated = false,
  });

  T data;
  DateTime? updatedAt;
  bool invalidated;
  int revision = 0;
  Timer? _gcTimer;
}

/// 与 TanStack Query `staleTime` / `cacheTime` 对应的内存缓存策略。
class QueryCachePolicy {
  const QueryCachePolicy({
    this.staleTime = const Duration(minutes: 10),
    this.cacheTime = const Duration(minutes: 5),
  });

  final Duration staleTime;
  final Duration cacheTime;
}

/// 全局 Query Map，统一负责缓存、请求去重、失效与垃圾回收。
class QueryClient {
  final Map<QueryKey, QueryCacheEntry<Object?>> _entries = {};
  final Map<QueryKey, Future<Object?>> _inFlight = {};
  int _generation = 0;

  Map<QueryKey, QueryCacheEntry<Object?>> get entries =>
      UnmodifiableMapView(_entries);

  bool containsQuery(QueryKey key) => _entries.containsKey(key);

  T? getQueryData<T>(QueryKey key) {
    final data = _entries[key]?.data;
    return data is T ? data : null;
  }

  /// 首次遇到 key 时注册默认状态；已存在时直接返回同一份缓存数据。
  T registerQuery<T>(QueryKey key, T initialData) {
    final entry = _entries.putIfAbsent(
      key,
      () => QueryCacheEntry<Object?>(data: initialData, updatedAt: null),
    );
    if (entry.data == null && entry.updatedAt == null) {
      entry.data = initialData;
    }
    final data = entry.data;
    if (data is! T) {
      throw StateError('$key was registered with a different data type');
    }
    return data;
  }

  void setQueryData<T>(QueryKey key, T data) {
    final entry = _entries.putIfAbsent(
      key,
      () => QueryCacheEntry<Object?>(data: data, updatedAt: null),
    );
    entry
      ..data = data
      ..updatedAt = DateTime.now()
      ..invalidated = false;
  }

  bool isStale(QueryKey key, Duration staleTime) {
    final entry = _entries[key];
    final updatedAt = entry?.updatedAt;
    return entry?.invalidated == true ||
        updatedAt == null ||
        DateTime.now().difference(updatedAt) >= staleTime;
  }

  Future<T> fetchQuery<T>({
    required QueryKey key,
    required Future<T> Function() queryFn,
    QueryCachePolicy policy = const QueryCachePolicy(),
    bool force = false,
  }) async {
    final entry = _entries.putIfAbsent(
      key,
      () => QueryCacheEntry<Object?>(data: null, updatedAt: null),
    );
    final cached = getQueryData<T>(key);
    if (!force && cached != null && !isStale(key, policy.staleTime)) {
      return cached;
    }
    final pending = _inFlight[key];
    if (pending != null) return (await pending) as T;

    final requestRevision = entry.revision;
    final requestGeneration = _generation;
    final request = queryFn();
    _inFlight[key] = request;
    try {
      final data = await request;
      if (_generation == requestGeneration &&
          identical(_entries[key], entry) &&
          entry.revision == requestRevision) {
        setQueryData(key, data);
      }
      return data;
    } finally {
      if (identical(_inFlight[key], request)) {
        _inFlight.remove(key);
      }
    }
  }

  Future<void> prefetchQuery<T>({
    required QueryKey key,
    required Future<T> Function() queryFn,
    QueryCachePolicy policy = const QueryCachePolicy(),
    bool force = false,
  }) async {
    await fetchQuery(
      key: key,
      queryFn: queryFn,
      policy: policy,
      force: force,
    );
  }

  void markActive(QueryKey key) {
    final entry = _entries[key];
    entry?._gcTimer?.cancel();
    if (entry != null) entry._gcTimer = null;
  }

  void markInactive(QueryKey key, Duration cacheTime) {
    final entry = _entries[key];
    if (entry == null) return;
    entry._gcTimer?.cancel();
    entry._gcTimer = Timer(cacheTime, () => removeQuery(key));
  }

  void removeQuery(QueryKey key) {
    _entries.remove(key)?._gcTimer?.cancel();
  }

  void invalidateQueries(QueryKey prefix) {
    for (final MapEntry(key: key, value: entry) in _entries.entries) {
      if (key.startsWith(prefix)) {
        entry
          ..invalidated = true
          ..revision += 1;
        _inFlight.remove(key);
      }
    }
  }

  void removeQueries(QueryKey prefix) {
    final keys = _entries.keys.where((key) => key.startsWith(prefix)).toList();
    for (final key in keys) {
      removeQuery(key);
    }
  }

  void clear() {
    _generation += 1;
    for (final entry in _entries.values) {
      entry._gcTimer?.cancel();
    }
    _entries.clear();
  }

  void dispose() {
    clear();
    _inFlight.clear();
  }
}

final queryClientProvider = Provider<QueryClient>((ref) {
  final client = QueryClient();
  ref.onDispose(client.dispose);
  return client;
});

/// 全应用列表查询的默认缓存策略，可在测试或特定 ProviderScope 中覆盖。
final queryCachePolicyProvider = Provider<QueryCachePolicy>(
  (ref) => const QueryCachePolicy(),
);

abstract class CachedQueryNotifier<State> extends StateNotifier<State> {
  CachedQueryNotifier(
    super.state, {
    required this.queryClient,
    required this.queryKey,
  });

  final QueryClient queryClient;
  final QueryKey queryKey;

  Future<void> loadFirstPage();

  void cacheCurrentState() {
    queryClient.setQueryData(queryKey, state);
  }

  void refetchIfStale(Duration staleTime) {
    if (queryClient.isStale(queryKey, staleTime)) {
      unawaited(loadFirstPage());
    }
  }
}

/// 把 autoDispose Provider 的监听生命周期连接到全局 Query Map。
void attachQueryCache<State>(
  Ref<State> ref,
  CachedQueryNotifier<State> notifier,
  QueryCachePolicy policy,
) {
  notifier.queryClient.markActive(notifier.queryKey);
  ref.onCancel(
    () =>
        notifier.queryClient.markInactive(notifier.queryKey, policy.cacheTime),
  );
  ref.onResume(() {
    notifier.queryClient.markActive(notifier.queryKey);
    notifier.refetchIfStale(policy.staleTime);
  });
}
