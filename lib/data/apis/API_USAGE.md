# 服务端 API 调用示例

网络请求统一经由 `DioController`，业务接口按服务域放在本目录。Widget 不应自行创建 Dio；在 Riverpod Store/Notifier 中通过 Provider 获取 API。

列表和可复用请求统一接入全局 `QueryClient`，不要在页面内自行维护 Map 或 Timer。缓存
key、`staleTime`、`cacheTime`、失效规则和分页接入方式见
[`../../core/query/QUERY_CACHE.md`](../../core/query/QUERY_CACHE.md)。

```dart
import '../data/apis/api_providers.dart';

final api = ref.read(cocktailApiProvider);
```

## 接口语言

`cocktailApiProvider` 自动使用当前 App 语言；用户酒单的本地化读取使用
`localizedUserApiProvider`。认证/资料仍使用稳定的 `userApiProvider`，不会因切换语言重建会话。
分类、列表、详情、随机、推荐、今日推荐、我的酒单和收藏八个 GET 端点发送 `lang=en` 或 `lang=zh`。
跟随系统时采用与 App 相同的语言解析，分页缓存按语言隔离。

非 Provider 调用可显式创建 `CocktailApi(lang: 'en')` / `UserApi(lang: 'en')`；默认中文。
`UserApi.myCocktailsPage`、`myCocktails`、`favoriteIds` 也可用命名参数 `lang` 覆盖。
写入接口不附加此参数。

语言变化由查询依赖统一触发：活跃查询自动重新读取；未活跃分页查询标记失效，
再次订阅时请求。切回曾用语言也重新验证，不因旧缓存尚在 staleTime 内而跳过请求。
语言设置页无需逐个调用接口，也不清除账户或其他不依赖语言的数据。

## 鸡尾酒接口

```dart
// 列表：支持基酒筛选和分页。
final cocktails = await api.list(spirit: 'gin', page: 1, limit: 20);

// 今日推荐。
final recommendations = await api.recommendations();

// 服务端随机抽选；基酒为空时不筛选。
final selected = await api.random(spirit: 'whiskey');

// 详情。不存在时服务端会抛出 ApiException(code: 1404)。
final cocktail = await api.detail('ne');
```

## 创建与修改私人酒单

`CocktailUpsertRequest` 只序列化非空字段；所以可以安全用于 `PATCH` 局部更新。创建时 `zh`、`base`（或 `spirit`）和 `recipe` 为必填字段。

```dart
import '../data/apis/cocktail_api.dart';
import '../models/cocktail.dart';

final request = CocktailUpsertRequest(
  zh: '午夜花园',
  en: 'Midnight Garden',
  base: '金酒',
  abv: 22,
  color: '#4FB3A6',
  tags: const ['花香', '清新'],
  images: const ['https://cdn.example.com/cover.webp'],
  glass: '碟形杯',
  garnish: '迷迭香',
  flavor: '清凉花香与草本尾韵。',
  story: '为安静的午夜准备。',
  recipe: const [
    RecipeItem(n: '金酒', ml: 50),
    RecipeItem(n: '橙味苦精', t: '1 dash'),
  ],
  steps: const ['加入冰块摇匀。', '双重过滤到冰镇杯中。'],
);

final created = await api.create(request);

// 仅修改酒精度和标签。
final updated = await api.update(
  created.id,
  const CocktailUpsertRequest(abv: 24, tags: ['花香', '草本']),
);

await api.delete(updated.id);
```

## 上传图片

先上传图片，再将返回 URL 填入创建或更新请求的 `images` 字段。

```dart
import 'package:dio/dio.dart';
import '../data/apis/api_providers.dart';

final uploadApi = ref.read(uploadApiProvider);
final file = await MultipartFile.fromFile('/absolute/path/cover.webp');
final imageUrl = await uploadApi.uploadImage(
  file,
  purpose: UploadPurpose.cocktail,
);
```

## 错误处理

所有网络与业务错误均转换为 `ApiException`。业务错误需优先看 `code`：例如 `1404` 是资源不存在，`1409` 是官方酒单禁止修改或删除。

```dart
import '../core/network/api_exception.dart';

try {
  await api.delete(cocktailId);
} on ApiException catch (error) {
  // 例如在 Store 中写入错误状态，交给页面显示 Toast。
  debugPrint('${error.code}: ${error.message}');
}
```

> 真机调试不能使用手机自身的 `localhost`。请通过 `--dart-define` 或环境配置将 `Env.baseUrl` 指向电脑局域网 IP 或正式域名。
