import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drinks/core/network/dio_controller.dart';
import 'package:drinks/data/apis/upload_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cocktail upload uses purpose query and exact file field', () async {
    RequestOptions? captured;
    final dio = Dio(BaseOptions(baseUrl: 'https://dash.shuke.me/api/v1'))
      ..httpClientAdapter = _UploadAdapter((options) async {
        captured = options;
        return ResponseBody.fromString(
          jsonEncode({
            'code': 0,
            'message': 'ok',
            'data': {'url': 'https://dash.shuke.me/static/image.webp'},
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
    final api = UploadApi(controller: DioController(dio: dio));

    final url = await api.uploadImage(
      MultipartFile.fromBytes([0xFF, 0xD8, 0xFF], filename: 'image.jpg'),
      purpose: UploadPurpose.cocktail,
    );

    expect(url, 'https://dash.shuke.me/static/image.webp');
    expect(captured?.method, 'POST');
    expect(captured?.path, '/upload/image');
    expect(captured?.queryParameters, {'purpose': 'cocktail'});
    final form = captured?.data as FormData;
    expect(form.files.single.key, 'file');
  });
}

class _UploadAdapter implements HttpClientAdapter {
  _UploadAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      handler(options);

  @override
  void close({bool force = false}) {}
}
