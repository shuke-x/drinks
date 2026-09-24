import '../../core/network/dio_controller.dart';
import '../../models/drink_record.dart';

class DrinkRecordApi {
  DrinkRecordApi({DioController? controller})
      : _controller = controller ?? DioController();
  final DioController _controller;
  static const _path = '/users/me/drink-records';

  Future<T> _request<T>(String account, String method, String path,
          {Object? data,
          Map<String, dynamic>? query,
          required T Function(dynamic) decoder}) =>
      _controller.send(method, path,
          headers: {'X-Record-Account': account},
          data: data,
          queryParameters: query,
          decoder: decoder);

  Future<List<DrinkRecord>> load(String account) async {
    final records = <String, DrinkRecord>{};
    var page = 1;
    while (true) {
      final result = await _request(account, 'GET', _path,
          query: {'page': page, 'limit': 20},
          decoder: (data) => Map<String, dynamic>.from(data as Map));
      final items = result['items'] as List;
      for (final item in items) {
        final record =
            DrinkRecord.fromJson(Map<String, dynamic>.from(item as Map));
        records[record.id] = record;
      }
      if (page * 20 >= (result['total'] as num) || items.isEmpty) break;
      page++;
    }
    return records.values.toList();
  }

  Future<void> importRecord(String account, DrinkRecord record) =>
      _request(account, 'POST', '$_path/import',
          data: record.toJson(), decoder: (_) {});
  Future<DrinkRecord> save(String account, DrinkRecord record,
          {required bool create}) =>
      _request(account, create ? 'POST' : 'PATCH',
          create ? _path : '$_path/${Uri.encodeComponent(record.id)}',
          data: record.toJson(),
          decoder: (data) =>
              DrinkRecord.fromJson(Map<String, dynamic>.from(data as Map)));
  Future<void> submit(String account, DrinkRecord record, String caption,
          List<int> photos) =>
      _request(
          account, 'POST', '$_path/${Uri.encodeComponent(record.id)}/submit',
          data: {
            'version': record.version,
            'caption': caption,
            'photoIndexes': photos
          },
          decoder: (_) {});
  Future<void> withdraw(String account, DrinkRecord record) => _request(
      account, 'POST', '$_path/${Uri.encodeComponent(record.id)}/withdraw',
      data: {'version': record.version}, decoder: (_) {});
  Future<void> remove(String account, String id, {required int version}) =>
      _request(account, 'DELETE', '$_path/${Uri.encodeComponent(id)}',
          data: {'version': version}, decoder: (_) {});
}
