import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cocktail_api.dart';
import '../../stores/locale_store.dart';
import '../../core/query/query_cache.dart';
import 'auth_api.dart';
import 'upload_api.dart';
import 'user_api.dart';

/// Invalidate language-dependent pages before their consumers rebuild. Keeping
/// the data permits same-language placeholders, but returning to a previously
/// used language must still fetch fresh data instead of trusting staleTime.
final Provider<String> cocktailQueryLanguageProvider = Provider<String>((ref) {
  final lang = ref.watch(appLanguageProvider);
  final queries = ref.read(queryClientProvider);
  queries.invalidateQueries(const QueryKey(['cocktail-feed']));
  queries.invalidateQueries(const QueryKey(['my-cocktails']));
  return lang;
});

/// 页面/Store 取得服务端接口的统一注入入口。
///
/// 页面建议由对应 Store 调用这些 Provider，避免在 Widget 内新建 Dio 或 API 实例。
final cocktailApiProvider = Provider<CocktailApi>(
    (ref) => CocktailApi(lang: ref.watch(cocktailQueryLanguageProvider)));

final cocktailCategoriesProvider = FutureProvider<List<CocktailCategory>>(
  (ref) => ref.watch(cocktailApiProvider).categories(),
);

final uploadApiProvider = Provider<UploadApi>((ref) => UploadApi());

final authApiProvider = Provider<AuthApi>((ref) => AuthApi());

final userApiProvider = Provider<UserApi>((ref) => UserApi());

/// Localized reads stay separate from the stable authentication/profile API.
final localizedUserApiProvider = Provider<UserApi>(
    (ref) => UserApi(lang: ref.watch(cocktailQueryLanguageProvider)));
