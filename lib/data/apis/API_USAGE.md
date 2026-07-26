# 服务端 API 调用示例

网络请求统一经由 `DioController`，业务接口按服务域放在本目录。Widget 不应自行创建 Dio；在 Riverpod Store/Notifier 中通过 Provider 获取 API。

```dart
import '../data/apis/api_providers.dart';

final api = ref.read(cocktailApiProvider);
```

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
final imageUrl = await uploadApi.uploadImage(file);
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
