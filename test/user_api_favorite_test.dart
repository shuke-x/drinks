import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drinks/core/network/dio_controller.dart';
import 'package:drinks/data/apis/user_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('favorite mutations call the users/me API with cocktailId', () async {
    final requests = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://dash.shuke.me/api/v1'))
      ..httpClientAdapter = _FavoriteAdapter((options) async {
        requests.add(options);
        return ResponseBody.fromString(
          jsonEncode({
            'code': 0,
            'message': 'ok',
            'data': {'success': true}
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
    final api = UserApi(controller: DioController(dio: dio));

    await api.addFavorite('cocktail-1');
    await api.removeFavorite('cocktail-1');

    expect(requests, hasLength(2));
    expect(requests[0].method, 'POST');
    expect(requests[0].path, '/users/me/favorites');
    expect(requests[0].data, {'cocktailId': 'cocktail-1'});
    expect(requests[1].method, 'DELETE');
    expect(requests[1].path, '/users/me/favorites');
    expect(requests[1].data, {'cocktailId': 'cocktail-1'});
  });
}

class _FavoriteAdapter implements HttpClientAdapter {
  _FavoriteAdapter(this.handler);

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
