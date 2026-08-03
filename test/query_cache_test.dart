import 'dart:async';

import 'package:drinks/core/query/query_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registerQuery creates one entry per key', () {
    final client = QueryClient();
    addTearDown(client.dispose);
    const key = QueryKey(['cocktails', 'gin']);

    final first = client.registerQuery(key, <String>['first']);
    final second = client.registerQuery(key, <String>['second']);

    expect(first, ['first']);
    expect(second, ['first']);
    expect(client.entries, hasLength(1));
  });

  test('fetchQuery deduplicates concurrent requests for the same key',
      () async {
    final client = QueryClient();
    addTearDown(client.dispose);
    const key = QueryKey(['cocktails', 'recommendations']);
    final response = Completer<List<String>>();
    var requestCount = 0;

    Future<List<String>> queryFn() {
      requestCount += 1;
      return response.future;
    }

    final first = client.fetchQuery(key: key, queryFn: queryFn);
    final second = client.fetchQuery(key: key, queryFn: queryFn);
    expect(requestCount, 1);

    response.complete(['negroni']);
    expect(await first, ['negroni']);
    expect(await second, ['negroni']);
    expect(client.getQueryData<List<String>>(key), ['negroni']);
  });

  test('invalidateQueries marks matching keys stale without deleting data', () {
    final client = QueryClient();
    addTearDown(client.dispose);
    client
      ..setQueryData(const QueryKey(['my-cocktails', 'draft']), 1)
      ..setQueryData(const QueryKey(['my-cocktails', 'pending']), 2)
      ..setQueryData(const QueryKey(['cocktail-feed', 'gin']), 3)
      ..invalidateQueries(const QueryKey(['my-cocktails']));

    expect(client.entries, hasLength(3));
    expect(
      client.isStale(
        const QueryKey(['my-cocktails', 'draft']),
        const Duration(days: 1),
      ),
      isTrue,
    );
    expect(
      client.getQueryData<int>(
        const QueryKey(['my-cocktails', 'pending']),
      ),
      2,
    );
    expect(
      client.isStale(
        const QueryKey(['cocktail-feed', 'gin']),
        const Duration(days: 1),
      ),
      isFalse,
    );
  });

  test('an invalidated in-flight response cannot overwrite newer data',
      () async {
    final client = QueryClient();
    addTearDown(client.dispose);
    const key = QueryKey(['my-cocktails', 'draft']);
    final oldResponse = Completer<List<String>>();

    final oldRequest = client.fetchQuery(
      key: key,
      queryFn: () => oldResponse.future,
    );
    client
      ..invalidateQueries(const QueryKey(['my-cocktails']))
      ..setQueryData(key, <String>['new']);

    oldResponse.complete(['old']);
    expect(await oldRequest, ['old']);
    expect(client.getQueryData<List<String>>(key), ['new']);
  });
}
