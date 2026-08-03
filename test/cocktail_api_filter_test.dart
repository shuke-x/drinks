import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drinks/core/network/dio_controller.dart';
import 'package:drinks/data/apis/cocktail_api.dart';
import 'package:drinks/models/cocktail.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('category list sends category code as spirit query', () async {
    RequestOptions? captured;
    final dio = Dio(BaseOptions(baseUrl: 'https://dash.shuke.me/api/v1'))
      ..httpClientAdapter = _FilterAdapter((options) async {
        captured = options;
        return ResponseBody.fromString(
          jsonEncode({
            'code': 0,
            'message': 'ok',
            'data': [],
            'meta': {'page': 1, 'limit': 20, 'total': 0},
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

    final page = await CocktailApi(controller: DioController(dio: dio))
        .listPage(spirit: 'gin');

    expect(captured?.path, '/cocktails');
    expect(captured?.queryParameters['spirit'], 'gin');
    expect(captured?.queryParameters['page'], 1);
    expect(captured?.queryParameters['limit'], 20);
    expect(page.page, 1);
    expect(page.total, 0);
    expect(page.hasMore, isFalse);
  });

  test('cocktail recipe accepts decimal milliliter amounts', () {
    final cocktail = Cocktail.fromJson({
      'id': 'last-word',
      'zh': '最后一语',
      'en': 'Last Word',
      'spirit': 'gin',
      'base': '金酒',
      'abv': 22,
      'color': '#0A84FF',
      'tags': <String>[],
      'glass': '鸡尾酒杯',
      'garnish': '',
      'flavor': '',
      'story': '',
      'recipe': [
        {'n': '金酒', 'ml': 22.5},
      ],
      'steps': <String>[],
    });

    expect(cocktail.recipe.single.ml, 22.5);
  });

  test('cocktail parses ownership workflow fields', () {
    final cocktail = Cocktail.fromJson({
      'id': 'draft-1',
      'zh': '草稿',
      'en': 'Draft',
      'spirit': 'gin',
      'base': '金酒',
      'status': 'rejected',
      'isPrivate': false,
      'rejectReason': '请补充步骤',
      'recipe': [
        {'n': '金酒', 'ml': 30},
      ],
    });

    expect(cocktail.status, CocktailStatus.rejected);
    expect(cocktail.isPrivate, isFalse);
    expect(cocktail.rejectReason, '请补充步骤');
  });

  test('public creation submits the created draft for review', () async {
    final api = _WorkflowCocktailApi();

    final result = await api.createForReview(
      const CocktailUpsertRequest(zh: '待审核酒单'),
    );

    expect(api.operations, ['create', 'submit:created-draft']);
    expect(result.status, CocktailStatus.pending);
  });
}

class _WorkflowCocktailApi extends CocktailApi {
  final List<String> operations = [];

  @override
  Future<Cocktail> create(CocktailUpsertRequest request) async {
    operations.add('create');
    return _cocktail('created-draft', CocktailStatus.draft);
  }

  @override
  Future<Cocktail> submit(String id) async {
    operations.add('submit:$id');
    return _cocktail(id, CocktailStatus.pending);
  }
}

Cocktail _cocktail(String id, CocktailStatus status) => Cocktail(
      id: id,
      zh: '测试酒单',
      en: 'Test Drink',
      base: '金酒',
      abv: 20,
      color: '#0A84FF',
      tags: const [],
      glass: '',
      garnish: '',
      flavor: '',
      story: '',
      recipe: const [],
      steps: const [],
      status: status,
    );

class _FilterAdapter implements HttpClientAdapter {
  _FilterAdapter(this.handler);

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
