import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cocktail.dart';

/// 本地持久化：我的酒单 + 计量单位。
/// 键名沿用原型 localStorage 键 'tonight-drinks-v1'。
class StorageService {
  static const _key = 'tonight-drinks-v1';

  Future<({List<Cocktail> mine, String unit})> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return (mine: <Cocktail>[], unit: 'ml');
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final mine = (map['mine'] as List? ?? const [])
          .map((e) => Cocktail.fromJson(e as Map<String, dynamic>))
          .toList();
      final unit = map['unit'] as String? ?? 'ml';
      return (mine: mine, unit: unit);
    } catch (_) {
      return (mine: <Cocktail>[], unit: 'ml');
    }
  }

  Future<void> save(
      {required List<Cocktail> mine, required String unit}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({'mine': mine.map((e) => e.toJson()).toList(), 'unit': unit}),
    );
  }

  /// 导出 JSON 字符串（原型为浏览器下载，移动端改为复制/分享）。
  String exportJson({required List<Cocktail> mine, required String unit}) =>
      const JsonEncoder.withIndent('  ').convert(
          {'mine': mine.map((e) => e.toJson()).toList(), 'unit': unit});
}
