import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/cocktail_repository.dart';
import '../models/cocktail.dart';
import 'settings_store.dart';

/// 仓库单例（测试时可 override 注入 fake）。
final cocktailRepositoryProvider = Provider<CocktailRepository>((ref) {
  return CocktailRepository();
});

/// 内置/官方酒单。
final builtinDrinksProvider = FutureProvider<List<Cocktail>>((ref) async {
  final drinks = await ref.watch(cocktailRepositoryProvider).getAll();
  debugPrint('[CocktailStore] list (${drinks.length})\n'
      '${const JsonEncoder.withIndent('  ').convert(drinks.map((e) => e.toJson()).toList())}');
  return drinks;
});

/// 今日推荐（Home 轮播，原型取前 4 款）。
final recommendationsProvider = FutureProvider<List<Cocktail>>((ref) async {
  final drinks =
      await ref.watch(cocktailRepositoryProvider).getRecommendations();
  debugPrint('[CocktailStore] recommendations (${drinks.length})\n'
      '${const JsonEncoder.withIndent('  ').convert(drinks.map((e) => e.toJson()).toList())}');
  return drinks;
});

/// 全部酒 = 内置 + 我的酒单（原型 all()）。
final allDrinksProvider = Provider<List<Cocktail>>((ref) {
  final builtin =
      ref.watch(builtinDrinksProvider).valueOrNull ?? const <Cocktail>[];
  final mine = ref.watch(appDataProvider).mine;
  return [...builtin, ...mine];
});

/// 按 id 查找（原型 find()）。
final drinkByIdProvider = Provider.family<Cocktail?, String>((ref, id) {
  final all = ref.watch(allDrinksProvider);
  for (final d in all) {
    if (d.id == id) {
      debugPrint('[CocktailStore] detail $id\n'
          '${const JsonEncoder.withIndent('  ').convert(d.toJson())}');
      return d;
    }
  }
  debugPrint('[CocktailStore] detail $id: not found');
  return null;
});

/// Home 当前分类。
final homeCategoryProvider = StateProvider<String>((ref) => '全部');

/// 基酒分类（原型 CATS）。
const kCategories = ['全部', '金酒', '威士忌', '朗姆', '龙舌兰', '伏特加', '其他'];

/// Home 瀑布流数据源（原型 gridSrc：分类筛选 all()）。
final homeGridProvider = Provider<List<Cocktail>>((ref) {
  final cat = ref.watch(homeCategoryProvider);
  final all = ref.watch(allDrinksProvider);
  return cat == '全部' ? all : all.where((d) => d.base == cat).toList();
});
