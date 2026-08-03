# 今晚喝什么 · Tonight Drinks

鸡尾酒酒单 Flutter App，100% 还原 Claude Design 毛玻璃设计稿。

三个 Tab：**Home**（今日推荐轮播 + 分类筛选 + 双列瀑布流）· **Next**（弧形卡组抽签选酒）· **System**（我的酒单管理 + 设置）。

## 技术栈

- Flutter 3.x（Dart >= 3.3）
- go_router（Shell 三 Tab + 详情/上传透明覆盖层路由）
- flutter_riverpod（状态管理）
- QueryClient（全局 Map 查询缓存、stale/cache 生命周期、并发去重）
- dio（上线后对接 NestJS 后端）
- shared_preferences（我的酒单 / 计量单位持久化）
- google_fonts（Noto Serif SC / Playfair Display / Hanken Grotesk / DM Mono）
- phosphor_flutter（Phosphor 图标，与设计稿一致）

## 运行

```bash
flutter pub get
flutter run                      # 默认 Mock 数据（assets/mock/cocktails.json）
```

> google_fonts 首次运行需联网拉取字体；若需离线，把字体文件放入 assets 并在 pubspec 声明。

## Mock / Remote 数据源切换

数据层是「接口 + 双实现」结构，业务只依赖 `CocktailRepository`：

```
CocktailDataSource（抽象接口）
 ├── CocktailMockDataSource    读 assets JSON + 300ms 模拟延迟
 └── CocktailRemoteDataSource  dio 调 NestJS API
```

切换方式（业务代码零改动）：

```bash
# Mock（默认）
flutter run

# 对接后端
flutter run --dart-define=DATA_SOURCE=remote --dart-define=FLAVOR=dev
```

后端 baseUrl 按环境配置在 `lib/core/config/env.dart`。

## 与 NestJS 后端的 API 契约

统一响应：`{ code, message, data, meta? }`（`lib/core/network/dio_client.dart` 中 `unwrap` 负责解包，code != 0 抛 `ApiException`）。

```
GET    /api/v1/cocktails?spirit=&page=&limit=    列表
GET    /api/v1/cocktails/:id                     详情
GET    /api/v1/cocktails/recommendations         今日推荐（Home 轮播）
POST   /api/v1/cocktails                         新建
PATCH  /api/v1/cocktails/:id                     更新
DELETE /api/v1/cocktails/:id                     删除（TypeORM 软删除）
POST   /api/v1/upload/image                      封面图上传（预留）
```

字段结构 = `assets/mock/cocktails.json` 的元素结构 = `Cocktail.toJson()` 输出，三处一致，联调即插即用。

## 目录结构

```
lib/
├── main.dart / app.dart
├── router/app_router.dart        # ShellRoute 三 Tab + /detail/:id、/upload 覆盖层
├── core/
│   ├── config/env.dart           # DATA_SOURCE / FLAVOR
│   ├── network/                  # dio 封装、统一响应解包、异常
│   ├── query/                    # QueryClient、全局 Map 缓存与接入文档
│   └── theme/                    # 颜色 / 字体 / 动效 / 间距 tokens（对应设计稿 tokens）
├── models/cocktail.dart
├── data/
│   ├── datasources/              # 抽象接口 + mock + remote
│   └── repositories/
├── services/storage_service.dart # 本地持久化（键 'tonight-drinks-v1'，同原型）
├── stores/                       # riverpod：酒单 / 设置 / Toast / 卡组物理引擎
├── components/                   # 氛围背景、毛玻璃组件、TabBar、渐变工具
└── views/                        # home / next / system / detail / upload / shell
```

## 设计还原要点

- **氛围系统**：3 个主题色光斑背景，随页面/卡片以 900ms `cubic-bezier(.32,.72,0,1)` 过渡。主题色逻辑：Home=当前推荐酒色，Next=居中卡酒色，System=`#5E5CE6`，详情=该酒颜色。
- **Next 弧形卡组**（`stores/deck_store.dart`，公式 1:1 移植原型 JS）：
  - 卡片 272×480，步距 296，圆弧 R=6000：`x=t·296`，`arc=R-√(R²-x²)`，`deg=atan2(x,R)`
  - 空闲巡航 0.115 卡/秒；拖拽 0.4 系数 lerp 跟手，松手速度钳制 ±2.6
  - 抽选 2500ms：缓动 `1-(1-k)^3.2`，最后 18% 叠加 `sin` 过冲(0.055)；命中金色 `#C9A227` 光晕 1.5s + 结果面板
- **动效 tokens**：standard `(.32,.72,0,1)` / easeOut `(.16,1,.3,1)` / spring `(.34,1.3,.64,1)`，按压缩放 0.96/140ms。

## 与原型的两处刻意偏差

1. **补充「随机抽选」按钮**（Next 页底部）：原型的 `spin()` 只挂在结果面板「再抽一次」上，缺少首次抽选入口（原型 bug），按设计语言补齐。
2. **导出数据**：原型为浏览器下载 JSON 文件，移动端改为复制到剪贴板 + Toast 提示。

## 备注

- 本项目在无 Flutter SDK 的环境中编写，**尚未经过编译验证**，首次 `flutter run` 如有小的 API 版本差异（如依赖 minor 版本变动）按报错微调即可。
- 上线切外部数据时，把用户上传（我的酒单）迁移到后端只需在 `AppDataNotifier` 里把持久化调用替换为 repository 的 create/update/delete。
