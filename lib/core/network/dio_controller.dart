import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'api_page.dart';
import 'dio_client.dart';

/// 所有服务端 API 共用的请求控制器。
///
/// 统一处理 NestJS 的 `{ code, message, data }` 响应、Dio 连接异常及超时，
/// 业务 API 只需要关心路径、参数和数据转换。
class DioController {
  DioController({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;

  /// Allows account-bound requests to retain their initiating identity through retries.
  Future<T> send<T>(
    String method,
    String path, {
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    Object? data,
    required T Function(dynamic data) decoder,
  }) =>
      _request(
          _dio.request(path,
              data: data,
              queryParameters: queryParameters,
              options: Options(method: method, headers: headers)),
          decoder);

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic data) decoder,
  }) =>
      _request(_dio.get(path, queryParameters: queryParameters), decoder);

  Future<ApiPage<T>> getPage<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required List<T> Function(dynamic data) decoder,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return DioClient.instance.unwrapPage(response, decoder);
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw _apiException(error);
    } catch (_) {
      throw const ApiException(message: '请求失败，请稍后重试');
    }
  }

  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic data) decoder,
  }) =>
      _request(
        _dio.post(path, data: data, queryParameters: queryParameters),
        decoder,
      );

  Future<T> patch<T>(
    String path, {
    Object? data,
    required T Function(dynamic data) decoder,
  }) =>
      _request(_dio.patch(path, data: data), decoder);

  Future<T> delete<T>(
    String path, {
    Object? data,
    required T Function(dynamic data) decoder,
  }) =>
      _request(_dio.delete(path, data: data), decoder);

  Future<T> _request<T>(
    Future<Response<dynamic>> request,
    T Function(dynamic data) decoder,
  ) async {
    try {
      final response = await request;
      return DioClient.instance.unwrap(response, decoder);
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw _apiException(error);
    } catch (_) {
      throw const ApiException(message: '请求失败，请稍后重试');
    }
  }

  ApiException _apiException(DioException error) {
    final body = error.response?.data;
    if (body is Map) {
      final message = body['message'];
      final code = body['code'];
      if (message is String && message.isNotEmpty) {
        return ApiException(
          code: code is int ? code : error.response?.statusCode ?? -1,
          message: message,
        );
      }
    }
    return ApiException(
      code: error.response?.statusCode ?? -1,
      message: _networkMessage(error),
    );
  }

  String _networkMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return '请求超时，请检查网络后重试';
      case DioExceptionType.connectionError:
        return '无法连接服务器，请确认服务已启动';
      default:
        return '网络请求失败，请稍后重试';
    }
  }
}
