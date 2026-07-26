import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'dio_client.dart';

/// 所有服务端 API 共用的请求控制器。
///
/// 统一处理 NestJS 的 `{ code, message, data }` 响应、Dio 连接异常及超时，
/// 业务 API 只需要关心路径、参数和数据转换。
class DioController {
  DioController({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic data) decoder,
  }) =>
      _request(_dio.get(path, queryParameters: queryParameters), decoder);

  Future<T> post<T>(
    String path, {
    Object? data,
    required T Function(dynamic data) decoder,
  }) =>
      _request(_dio.post(path, data: data), decoder);

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
      throw ApiException(message: _networkMessage(error));
    } catch (_) {
      throw const ApiException(message: '请求失败，请稍后重试');
    }
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
