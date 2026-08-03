import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drinks/core/auth/token_storage.dart';
import 'package:drinks/core/network/dio_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('concurrent 401 responses share one refresh and retry both requests',
      () async {
    final store = _MemoryTokenStore(
      const AuthTokens(accessToken: 'expired', refreshToken: 'refresh-1'),
    );
    var refreshRequests = 0;
    var protectedRequests = 0;

    final apiDio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'))
      ..httpClientAdapter = _FakeAdapter((options) async {
        protectedRequests++;
        final authorized = options.headers['Authorization'] == 'Bearer fresh';
        return _jsonResponse(
          authorized
              ? {
                  'code': 0,
                  'message': 'ok',
                  'data': {'success': true},
                }
              : {
                  'code': 401,
                  'message': 'Access token expired',
                  'data': null,
                },
          authorized ? 200 : 401,
        );
      });
    final refreshDio = Dio()
      ..httpClientAdapter = _FakeAdapter((options) async {
        refreshRequests++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(options.path, '/auth/refresh');
        final data = options.data is String
            ? jsonDecode(options.data as String)
            : options.data;
        expect(data, {'refreshToken': 'refresh-1'});
        return _jsonResponse({
          'code': 0,
          'message': 'ok',
          'data': {
            'accessToken': 'fresh',
            'refreshToken': 'refresh-2',
          },
        }, 200);
      });

    final client = DioClient.forTesting(
      dio: apiDio,
      refreshDio: refreshDio,
      tokenStore: store,
    );

    final responses = await Future.wait([
      client.dio.get<dynamic>('/protected/one'),
      client.dio.get<dynamic>('/protected/two'),
    ]);

    expect(responses.map((response) => response.statusCode), everyElement(200));
    expect(refreshRequests, 1);
    expect(protectedRequests, 4);
    expect((await store.read())?.accessToken, 'fresh');
    expect((await store.read())?.refreshToken, 'refresh-2');
  });

  test('failed refresh clears tokens and notifies the session owner', () async {
    final store = _MemoryTokenStore(
      const AuthTokens(accessToken: 'expired', refreshToken: 'invalid'),
    );
    final apiDio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'))
      ..httpClientAdapter = _FakeAdapter(
        (_) async => _jsonResponse({
          'code': 401,
          'message': 'Access token expired',
          'data': null,
        }, 401),
      );
    final refreshDio = Dio()
      ..httpClientAdapter = _FakeAdapter(
        (_) async => _jsonResponse({
          'code': 401,
          'message': 'Refresh token is invalid or expired',
          'data': null,
        }, 401),
      );
    final client = DioClient.forTesting(
      dio: apiDio,
      refreshDio: refreshDio,
      tokenStore: store,
    );
    var expiredNotifications = 0;
    client.onSessionExpired = () => expiredNotifications++;

    await expectLater(
      client.dio.get<dynamic>('/protected'),
      throwsA(isA<DioException>()),
    );

    expect(await store.read(), isNull);
    expect(expiredNotifications, 1);
  });
}

ResponseBody _jsonResponse(Map<String, dynamic> body, int statusCode) =>
    ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

class _MemoryTokenStore implements AuthTokenStore {
  _MemoryTokenStore(this.tokens);

  AuthTokens? tokens;

  @override
  Future<void> clear() async => tokens = null;

  @override
  Future<AuthTokens?> read() async => tokens;

  @override
  Future<String?> readAccessToken() async => tokens?.accessToken;

  @override
  Future<String?> readRefreshToken() async => tokens?.refreshToken;

  @override
  Future<void> save(AuthTokens value) async => tokens = value;
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

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
