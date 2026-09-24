import 'dart:async';
import '../data/apis/drink_record_api.dart';
import '../core/network/api_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/drink_record.dart';
import '../services/drink_record_storage.dart';
import 'user_store.dart';

final drinkRecordApiProvider =
    Provider<DrinkRecordApi?>((ref) => DrinkRecordApi());

final drinkRecordStorageProvider = Provider((ref) => DrinkRecordStorage());

final recordAccountProvider = Provider<String?>((ref) {
  final user = ref.watch(userProvider);
  return user.isLoggedIn ? user.id : null;
});

final drinkRecordsProvider =
    StateNotifierProvider<DrinkRecordsNotifier, AsyncValue<List<DrinkRecord>>>(
        (ref) {
  return DrinkRecordsNotifier(
    ref.watch(drinkRecordStorageProvider),
    ref.watch(recordAccountProvider),
    api: ref.watch(drinkRecordApiProvider),
  );
});

class DrinkRecordsNotifier
    extends StateNotifier<AsyncValue<List<DrinkRecord>>> {
  DrinkRecordsNotifier(this.storage, this.accountId, {this.api})
      : super(const AsyncLoading()) {
    ready = _load();
  }

  final DrinkRecordStorage storage;
  final DrinkRecordApi? api;
  final String? accountId;
  late final Future<void> ready;
  Future<void> _pending = Future.value();
  Timer? _expiryTimer;
  void _publish(List<DrinkRecord> items) {
    _expiryTimer?.cancel();
    final current = items.where((item) => !item.isExpired).toList();
    state = AsyncData(List.unmodifiable(current));
    final dates = current
        .map((item) => item.expiresAt)
        .whereType<DateTime>()
        .toList()
      ..sort();
    if (dates.isNotEmpty) {
      _expiryTimer = Timer(
          dates.first.difference(DateTime.now()) +
              const Duration(milliseconds: 100), () {
        if (mounted) _publish(state.valueOrNull ?? []);
      });
    }
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items = accountId == null ? <DrinkRecord>[] : await _loadAccount();
      items.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      if (mounted) _publish(items);
    } catch (error, stack) {
      if (mounted) state = AsyncError(error, stack);
    }
  }

  Future<List<DrinkRecord>> _loadAccount() async {
    final legacy = await storage.load(accountId!);
    final remote = api;
    if (remote == null) return legacy;
    for (final record in legacy) {
      if (!mounted) throw StateError('Account changed');
      await remote.importRecord(accountId!, record);
    }
    if (!mounted) throw StateError('Account changed');
    if (legacy.isNotEmpty) await storage.completeMigration(accountId!);
    return remote.load(accountId!);
  }

  Future<void> refresh() {
    final task = _pending.then((_) async {
      await ready;
      if (!mounted) return;
      await _load();
    });
    _pending = task.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return task;
  }

  Future<void> _change(List<DrinkRecord> Function(List<DrinkRecord>) operation,
      Future<void> Function(List<DrinkRecord>) remoteOperation) {
    final task = _pending.then((_) async {
      await ready;
      if (!mounted || accountId == null) {
        throw StateError('Sign in to save a record');
      }
      final next = operation(state.requireValue);
      next.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      if (api == null) {
        await storage.save(accountId!, next);
      } else {
        await remoteOperation(state.requireValue);
      }
      if (mounted) _publish(next);
    });
    _pending = task.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return task;
  }

  Future<void> save(DrinkRecord record) {
    final task = _pending.then((_) async {
      await ready;
      if (!mounted || accountId == null) throw StateError('Account changed');
      final items = state.requireValue;
      final create = !items.any((item) => item.id == record.id);
      if (!create && record.version == null && api != null) {
        throw const ApiException(
            code: 409, message: 'Reload the record before editing');
      }
      final saved = api == null
          ? record
          : await api!.save(accountId!, record, create: create);
      final next = [
        for (final item in items)
          if (item.id != saved.id) item,
        saved
      ]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      if (api == null) await storage.save(accountId!, next);
      if (mounted) _publish(next);
    });
    _pending = task.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return task;
  }

  Future<void> remove(String id) =>
      _change((items) => items.where((item) => item.id != id).toList(),
          (items) {
        final version = items.firstWhere((item) => item.id == id).version;
        if (version == null) {
          throw const ApiException(
              code: 409, message: 'Reload the record before deleting');
        }
        return api!.remove(accountId!, id, version: version);
      });
}
