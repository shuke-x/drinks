/// 业务/网络异常，供 UI 层统一展示。
class ApiException implements Exception {
  final int code;
  final String message;

  const ApiException({this.code = -1, required this.message});

  @override
  String toString() => 'ApiException($code): $message';
}
