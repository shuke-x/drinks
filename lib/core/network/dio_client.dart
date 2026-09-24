import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/env.dart';
import '../telemetry/app_telemetry.dart';
import '../auth/token_storage.dart';
import 'api_page.dart';
import 'api_exception.dart';

/// Dio 单例封装。
/// 对应 NestJS 统一响应结构：{ code, message, data, meta? }
class DioClient {
  DioClient._({
    Dio? dio,
    Dio? refreshDio,
    AuthTokenStore? tokenStore,
  })  : _tokenStore = tokenStore ?? TokenStorage.instance,
        _refreshDio = refreshDio ?? Dio() {
    _dio = dio ??
        Dio(BaseOptions(
          baseUrl: Env.baseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 12),
          headers: {'Content-Type': 'application/json'},
        ));

    _refreshDio.options = _dio.options.copyWith();

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 登录、challenge、refresh 本身不附加旧 access token。
        if (!_doesNotUseAccessToken(options.path)) {
          final token = await _tokenStore.readAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode != 401 ||
            _doesNotUseAccessToken(error.requestOptions.path)) {
          handler.next(error);
          return;
        }
        if (error.requestOptions.extra[_retriedKey] == true) {
          await _expireSession();
          handler.next(error);
          return;
        }
        try {
          final tokens = await _refreshOnce();
          final request = error.requestOptions;
          request.extra[_retriedKey] = true;
          request.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
          handler.resolve(await _dio.fetch<dynamic>(request));
        } on DioException catch (refreshError) {
          // A temporary outage must not destroy a valid refresh token.
          if (refreshError.response?.statusCode == 401 ||
              refreshError.response?.statusCode == 403) {
            await _expireSession();
          }
          handler.next(refreshError);
        } catch (_) {
          handler.next(error);
        }
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(onError: (error, handler) {
      AppTelemetry.network(error);
      handler.next(error);
    }));
  }

  @visibleForTesting
  factory DioClient.forTesting({
    required Dio dio,
    required Dio refreshDio,
    required AuthTokenStore tokenStore,
  }) =>
      DioClient._(
        dio: dio,
        refreshDio: refreshDio,
        tokenStore: tokenStore,
      );

  static final DioClient instance = DioClient._();
  static const _retriedKey = 'auth.retried-after-refresh';

  final AuthTokenStore _tokenStore;
  final Dio _refreshDio;
  late final Dio _dio;
  Future<AuthTokens>? _refreshing;

  FutureOr<void> Function()? onSessionExpired;

  Dio get dio => _dio;

  Future<AuthTokens> _refreshOnce() {
    final active = _refreshing;
    if (active != null) return active;
    final future = _performRefresh();
    _refreshing = future;
    return future.whenComplete(() {
      if (identical(_refreshing, future)) _refreshing = null;
    });
  }

  Future<AuthTokens> _performRefresh() async {
    final refreshToken = await _tokenStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw StateError('No refresh token');
    }
    final response = await _refreshDio.post<dynamic>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    final tokens = unwrap(response, (data) {
      final json = data as Map<String, dynamic>;
      return AuthTokens(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
      );
    });
    await _tokenStore.save(tokens);
    return tokens;
  }

  Future<void> _expireSession() async {
    await _tokenStore.clear();
    await onSessionExpired?.call();
  }

  bool _doesNotUseAccessToken(String path) => const {
        '/auth/challenge',
        '/auth/register',
        '/auth/login',
        '/auth/refresh',
        '/auth/logout',
      }.contains(path);

  /// 解包 NestJS 统一响应；code != 0 抛业务异常。
  T unwrap<T>(Response response, T Function(dynamic data) parser) {
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw const ApiException(message: '响应格式错误');
    }
    final code = body['code'] as int? ?? -1;
    if (code != 0) {
      throw ApiException(
        code: code,
        message: body['message'] as String? ?? '请求失败',
      );
    }
    return parser(body['data']);
  }

  ApiPage<T> unwrapPage<T>(
    Response response,
    List<T> Function(dynamic data) parser,
  ) {
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw const ApiException(message: '响应格式错误');
    }
    final code = body['code'] as int? ?? -1;
    if (code != 0) {
      throw ApiException(
        code: code,
        message: body['message'] as String? ?? '请求失败',
      );
    }
    final meta = body['meta'];
    if (meta is! Map<String, dynamic>) {
      throw const ApiException(message: '分页响应缺少 meta');
    }
    return ApiPage<T>(
      items: parser(body['data']),
      page: (meta['page'] as num?)?.toInt() ?? 1,
      limit: (meta['limit'] as num?)?.toInt() ?? 20,
      total: (meta['total'] as num?)?.toInt() ?? 0,
    );
  }
}
