import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/drink_record.dart';

/// Files live in application support, not the image picker's temporary cache.
/// Account IDs are encoded, never interpolated as filesystem paths.
class DrinkRecordStorage {
  DrinkRecordStorage({this.directory});
  final Directory? directory;
  final Map<String, Future<void>> _writes = {};

  Future<File> _file(String accountId) async {
    final root = directory ?? await getApplicationSupportDirectory();
    final recordsDirectory = Directory('${root.path}/drink-records');
    await recordsDirectory.create(recursive: true);
    final key = base64Url.encode(utf8.encode(accountId)).replaceAll('=', '');
    return File('${recordsDirectory.path}/$key.json');
  }

  Future<List<DrinkRecord>> load(String accountId) async {
    await _writes[accountId];
    final file = await _file(accountId);
    final migrated = File('${file.path}.migrated');
    if (await migrated.exists()) await migrated.delete();
    if (!await file.exists()) return [];
    final values = jsonDecode(await file.readAsString()) as List;
    // Surface corrupt data instead of silently replacing an existing journal.
    return values
        .map((value) =>
            DrinkRecord.fromJson(Map<String, dynamic>.from(value as Map)))
        .toList();
  }

  /// Remove legacy copies after acknowledgement so expiry has no local backup.
  Future<void> completeMigration(String accountId) async {
    await _writes[accountId];
    final file = await _file(accountId);
    if (await file.exists()) await file.delete();
    final migrated = File('${file.path}.migrated');
    if (await migrated.exists()) await migrated.delete();
  }

  Future<void> save(String accountId, List<DrinkRecord> records) {
    final task = (_writes[accountId] ?? Future<void>.value()).then((_) async {
      final file = await _file(accountId);
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(
          jsonEncode(records.map((item) => item.toJson()).toList()),
          flush: true);
      await temporary.rename(file.path);
    });
    _writes[accountId] =
        task.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return task;
  }
}
