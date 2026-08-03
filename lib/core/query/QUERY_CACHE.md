# Query 缓存

项目使用 `QueryClient` 统一管理内存查询缓存，语义参考
[TanStack Query v4 useQuery](https://tanstack.com/query/v4/docs/framework/react/reference/useQuery)。
实现位于 `lib/core/query/query_cache.dart`。

## 核心模型

`QueryClient` 内部维护两张 Map：

```dart
Map<QueryKey, QueryCacheEntry<Object?>> entries;
Map<QueryKey, Future<Object?>> inFlight;
```

- `entries` 保存查询数据、最后成功更新时间和垃圾回收计时器。
- `inFlight` 保存正在执行的请求。同一个 key 并发调用 `fetchQuery` 时复用同一个
  Future，避免重复请求。
- 每个 entry 维护 revision；invalidate、remove 或 clear 之后，较早发出的请求即使
  更晚返回，也不能覆盖新的缓存数据。
- `QueryKey` 是有顺序的 key 数组，例如 `['cocktail-feed', 'gin']`。
- 第一次调用 `registerQuery` 或 `fetchQuery` 时，如果 Map 中没有 key，会自动注册；
  已有 key 不会重复创建 entry。

## 缓存时间

默认策略：

```dart
const QueryCachePolicy(
  staleTime: Duration(minutes: 10),
  cacheTime: Duration(minutes: 5),
);
```

- `staleTime`：最后一次成功请求后，数据保持 fresh 的时间。fresh 数据重新进入页面时
  不请求；stale 数据重新进入时保留旧内容并后台刷新。
- `cacheTime`：查询无人监听后继续留在 Map 的时间。超过时间后删除 entry，下次进入
  从初始状态重新请求。
- 缓存只存在内存中，App 进程结束后自然清空；退出登录、删除账号或会话失效时主动
  调用 `QueryClient.clear()`。

## 直接查询

普通请求可以直接使用 `fetchQuery`：

```dart
final client = ref.read(queryClientProvider);
final data = await client.fetchQuery<List<Cocktail>>(
  key: const QueryKey(['recommendations']),
  queryFn: api.recommendations,
);
```

同 key 的 fresh 调用直接返回缓存；stale 或无缓存时发起请求；并发请求自动合并。

常用管理方法：

```dart
client.getQueryData<MyState>(key);
client.setQueryData(key, state);
client.removeQuery(key);
client.invalidateQueries(const QueryKey(['my-cocktails']));
client.removeQueries(const QueryKey(['my-cocktails']));
client.clear();
```

`invalidateQueries` 使用前缀匹配并把数据标记为 stale，但保留旧内容用于后台刷新；
`removeQueries` 才会删除匹配 entry。因此 `['my-cocktails']` 可以同时管理全部、草稿、
审核中等所有筛选缓存。

## StateNotifier / 分页列表接入

分页列表继承 `CachedQueryNotifier<State>`，请求成功后调用 `cacheCurrentState()`：

```dart
class ExampleNotifier extends CachedQueryNotifier<ExampleState> {
  ExampleNotifier(
    ExampleState initialState,
    QueryClient client,
    QueryKey key,
  ) : super(initialState, queryClient: client, queryKey: key);

  @override
  Future<void> loadFirstPage() async {
    final result = await repository.load();
    state = ExampleState(items: result);
    cacheCurrentState();
  }
}
```

Provider 创建流程固定为：

1. 根据 family 参数生成稳定 `QueryKey`。
2. 调用 `registerQuery(key, initialState)`；首次注册，后续复用。
3. 用返回的缓存 state 创建 Notifier。
4. 调用 `attachQueryCache` 连接 Riverpod 的监听/离开生命周期。
5. 调用 `refetchIfStale`，仅在无成功数据或数据已 stale 时请求。

当前接入模块：

- 首页分类：`['cocktail-feed', spirit]`
- 我的酒单：`['my-cocktails', status]`

## Mutation 后失效

新增、编辑、删除、提交审核或撤回审核后，必须先失效受影响的 key 前缀，再刷新对应
Provider。对于当前页面已经同步更新的 state，可以在前缀失效后调用
`cacheCurrentState()`，保留当前筛选结果，同时让其他筛选下次进入时重新请求。

不要只调用 `ref.invalidate(provider)`：如果 Query Map 中仍有 fresh 数据，新 Provider
会再次读取旧缓存。

## 测试覆盖

- key 首次注册与重复注册
- 同 key 并发请求去重
- fresh 缓存复用
- stale 后保留旧数据并后台刷新
- inactive cache 超时回收
- 首页分类和“我的酒单”的 family key 隔离
