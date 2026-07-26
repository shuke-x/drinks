import 'package:dio/dio.dart';

import '../config/env.dart';
import 'api_exception.dart';

/// Dio 单例封装。
/// 对应 NestJS 统一响应结构：{ code, message, data, meta? }
class DioClient {
  DioClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: Env.baseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 12),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // TODO(auth): 登录后在此注入 token
        // options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (e, handler) {
        handler.next(e);
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: Env.flavor != Flavor.prod,
      responseBody: Env.flavor != Flavor.prod,
    ));
  }

  static final DioClient instance = DioClient._();
  late final Dio _dio;

  Dio get dio => _dio;

  /// 解包 NestJS 统一响应；code != 0 抛业务异常。
  T unwrap<T>(Response response, T Function(dynamic data) parser) {
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw ApiException(message: '响应格式错误');
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
}
