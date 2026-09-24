# 今晚喝什么 · Tonight Drinks

Flutter 鸡尾酒 App，包含首页、风味推荐、配方和我的四个主 Tab，以及酒单创建、收藏、酒柜管理和品饮记录。

## 运行

```bash
flutter pub get
flutter run
```

默认连接真实服务 `https://dash.shuke.me/api/v1`，不使用默认 Mock。字体已随 App 打包，无需运行时下载。

连接开发服务器时显式指定地址（真机需使用可访问的局域网地址）：

```bash
flutter run --dart-define=FLAVOR=dev --dart-define=API_BASE_URL=http://192.168.1.10:3000/api/v1
```

环境配置见 `lib/core/config/env.dart`。默认环境为 prod；staging 地址目前为占位地址，应通过 `API_BASE_URL` 覆盖。

## 技术与目录

- Flutter、Riverpod、go_router：界面、状态与路由。
- Dio、QueryClient：真实 API 请求、认证刷新和查询缓存。
- flutter_secure_storage：认证凭据；shared_preferences：用户偏好。
- Cupertino 控件和自定义 UIKit Liquid Glass 桥接：iOS 系统交互。
- `lib/data/`：API 与数据仓库；`lib/models/`：业务模型。
- `lib/stores/`：业务状态；`lib/services/`：本地存储。
- `lib/views/`：业务页面；`lib/components/`：共享组件。
- `lib/core/`：网络、配置、导航和主题。

## 检查与构建

```bash
flutter analyze
flutter build ios --release --no-codesign
```

本地自动化测试、Driver 入口、测试截图及 iOS/macOS 测试 target 已按要求移除。当前没有本地自动化测试套件；删除测试不代表原有发布风险已经解决。

iOS 无签名构建可用于编译检查，安装和发布仍需签名。已完成事项、上线前提、生产部署顺序及待办统一见 [项目状态与上线准备](docs/PROJECT_STATUS_AND_RELEASE.md)；对象存储控制台操作见 [R2 配置流程](docs/CLOUDFLARE_R2_SETUP.md)。
