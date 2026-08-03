import 'dart:convert';

import 'package:basic_utils/basic_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart';

import '../../core/auth/token_storage.dart';
import '../../core/network/dio_controller.dart';

class AuthChallenge {
  const AuthChallenge({
    required this.challengeId,
    required this.publicKey,
    required this.nonce,
  });

  final String challengeId;
  final String publicKey;
  final String nonce;

  factory AuthChallenge.fromJson(Map<String, dynamic> json) => AuthChallenge(
        challengeId: json['challengeId'] as String,
        publicKey: json['publicKey'] as String,
        nonce: json['nonce'] as String,
      );
}

class AuthApi {
  AuthApi({DioController? controller})
      : _controller = controller ?? DioController();
  final DioController _controller;

  /// 登录：先领取一次性 challenge，再加密发送业务载荷。
  Future<AuthTokens> login({required String email, required String password}) =>
      _authenticate('/auth/login', email: email, password: password);

  /// 注册：与登录采用完全相同的加密通道，额外携带昵称。
  Future<AuthTokens> register({
    required String email,
    required String password,
    required String name,
  }) =>
      _authenticate('/auth/register',
          email: email, password: password, name: name);

  /// Token 刷新不使用 challenge，refresh token 仅存在于安全存储中。
  Future<AuthTokens> refresh(String refreshToken) => _controller.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        decoder: _tokens,
      );

  Future<void> logout(String refreshToken) => _controller.post(
        '/auth/logout',
        data: {'refreshToken': refreshToken},
        decoder: (_) {},
      );

  Future<AuthTokens> _authenticate(
    String path, {
    required String email,
    required String password,
    String? name,
  }) async {
    debugPrint('[AuthApi] GET /auth/challenge for $path');
    final challenge = await _controller.get(
      '/auth/challenge',
      decoder: (data) => AuthChallenge.fromJson(data as Map<String, dynamic>),
    );
    debugPrint('[AuthApi] challenge received; encrypting $path payload');
    // 密码只存在于本地变量及待加密 payload，不会写入 Store 或日志。
    final payload = jsonEncode({
      'email': email,
      'password': password,
      'nonce': challenge.nonce,
      if (name != null) 'name': name,
    });
    // RSA-2048 + OAEP-SHA256 单次最多加密约 190 bytes；challenge 的 nonce
    // 已提供时效与防重放能力，因此不再叠加 timestamp / requestId。
    debugPrint(
        '[AuthApi] encrypted payload size=${utf8.encode(payload).length} bytes');
    final ciphertext = _encryptOaepSha256(payload, challenge.publicKey);
    debugPrint('[AuthApi] POST $path with encrypted credentials');
    final tokens = await _controller.post(
      path,
      data: {'challengeId': challenge.challengeId, 'ciphertext': ciphertext},
      decoder: _tokens,
    );
    debugPrint('[AuthApi] POST $path succeeded');
    return tokens;
  }

  /// 服务端协议指定 RSA-OAEP + SHA-256。
  String _encryptOaepSha256(String plaintext, String pem) {
    final publicKey = CryptoUtils.rsaPublicKeyFromPem(pem);
    final cipher = OAEPEncoding.withSHA256(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
    final encrypted =
        cipher.process(Uint8List.fromList(utf8.encode(plaintext)));
    return base64Encode(encrypted);
  }

  static AuthTokens _tokens(dynamic data) {
    final json = data as Map<String, dynamic>;
    return AuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }
}
