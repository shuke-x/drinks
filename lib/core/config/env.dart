/// 运行环境。
enum Flavor { dev, staging, prod }

/// 全局环境配置。
///
/// 服务端地址可按运行环境或 `API_BASE_URL` 覆盖。
/// 也可通过 --dart-define 注入：
///   flutter run --dart-define=DATA_SOURCE=remote --dart-define=API_BASE_URL=http://192.168.1.10:3000/api/v1
class Env {
  Env._();

  static const Flavor flavor =
      String.fromEnvironment('FLAVOR', defaultValue: 'prod') == 'prod'
          ? Flavor.prod
          : (String.fromEnvironment('FLAVOR', defaultValue: 'prod') == 'staging'
              ? Flavor.staging
              : Flavor.dev);

  /// 默认连接正式服务；本地开发可通过参数显式覆盖。
  static const String _apiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  /// NestJS 后端地址（与后端 docker-compose 对齐）。
  static String get baseUrl {
    if (_apiBaseUrl.isNotEmpty) return _apiBaseUrl;
    switch (flavor) {
      case Flavor.prod:
        return 'https://dash.shuke.me/api/v1';
      case Flavor.staging:
        return 'https://staging-api.tonight-drinks.example.com/api/v1';
      case Flavor.dev:
        return 'http://localhost:3000/api/v1';
    }
  }
}
