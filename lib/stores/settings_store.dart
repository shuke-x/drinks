import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cocktail.dart';
import '../services/storage_service.dart';

/// 应用本地数据：我的酒单 + 计量单位。
class AppData {
  final List<Cocktail> mine;
  final String unit; // 'ml' | 'oz'
  const AppData({this.mine = const [], this.unit = 'ml'});

  AppData copyWith({List<Cocktail>? mine, String? unit}) =>
      AppData(mine: mine ?? this.mine, unit: unit ?? this.unit);
}

class AppDataNotifier extends StateNotifier<AppData> {
  AppDataNotifier(this._storage) : super(const AppData()) {
    _restore();
  }

  final StorageService _storage;

  Future<void> _restore() async {
    final data = await _storage.load();
    state = AppData(mine: data.mine, unit: data.unit);
  }

  void _persist() => _storage.save(mine: state.mine, unit: state.unit);

  void setUnit(String unit) {
    state = state.copyWith(unit: unit);
    _persist();
  }

  /// 新增或更新（editId != null 时为编辑，逻辑同原型 saveForm）。
  void upsert(Cocktail item, {String? editId}) {
    final mine = editId != null
        ? state.mine.map((m) => m.id == editId ? item : m).toList()
        : [...state.mine, item];
    state = state.copyWith(mine: mine);
    _persist();
  }

  void remove(String id) {
    state = state.copyWith(mine: state.mine.where((m) => m.id != id).toList());
    _persist();
  }

  /// 登录后以服务端数据为准，避免不同账号之间混入本地私人酒单缓存。
  void replaceMine(List<Cocktail> mine) {
    state = state.copyWith(mine: List.unmodifiable(mine));
    _persist();
  }

  void clear() {
    state = state.copyWith(mine: const []);
    _persist();
  }

  String exportJson() =>
      _storage.exportJson(mine: state.mine, unit: state.unit);
}

final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService());

final appDataProvider = StateNotifierProvider<AppDataNotifier, AppData>(
  (ref) => AppDataNotifier(ref.watch(storageServiceProvider)),
);

/// 用量文案（原型 amount()：oz 取 1/4 精度）。
String formatAmount(RecipeItem r, String unit) {
  if (r.t != null && r.t!.isNotEmpty) return r.t!;
  final ml = r.ml ?? 0;
  if (unit == 'oz') {
    final oz = (ml / 29.5735 * 4).round() / 4;
    var s = oz.toStringAsFixed(2);
    if (s.endsWith('0')) s = s.substring(0, s.length - 1);
    return '$s oz';
  }
  return '$ml ml';
}

/// 顶部气泡 Toast。给动态文字和辅助技术留出足够读取时间。
class ToastNotifier extends StateNotifier<String> {
  ToastNotifier() : super('');
  Timer? _timer;

  void show(String message) {
    _timer?.cancel();
    state = message;
    _timer = Timer(const Duration(seconds: 4), () => state = '');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final toastProvider =
    StateNotifierProvider<ToastNotifier, String>((ref) => ToastNotifier());
