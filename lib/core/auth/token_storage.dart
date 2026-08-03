import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 仅保存服务端签发的 Token。iOS 使用 Keychain、Android 使用 Keystore。
class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});
  final String accessToken;
  final String refreshToken;
}

abstract interface class AuthTokenStore {
  Future<AuthTokens?> read();
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> save(AuthTokens tokens);
  Future<void> clear();
}

class TokenStorage implements AuthTokenStore {
  TokenStorage._();
  static final instance = TokenStorage._();

  static const _accessKey = 'auth.access-token';
  static const _refreshKey = 'auth.refresh-token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<AuthTokens?> read() async {
    final accessToken = await _storage.read(key: _accessKey);
    final refreshToken = await _storage.read(key: _refreshKey);
    if (accessToken == null || refreshToken == null) return null;
    return AuthTokens(accessToken: accessToken, refreshToken: refreshToken);
  }

  @override
  Future<String?> readAccessToken() => _storage.read(key: _accessKey);

  @override
  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);

  /// 逐项写入，避免将密码或其他认证表单字段带入安全存储。
  @override
  Future<void> save(AuthTokens tokens) async {
    await _storage.write(key: _accessKey, value: tokens.accessToken);
    await _storage.write(key: _refreshKey, value: tokens.refreshToken);
  }

  @override
  Future<void> clear() => Future.wait([
        _storage.delete(key: _accessKey),
        _storage.delete(key: _refreshKey),
      ]);
}
