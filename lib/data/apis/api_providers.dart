import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cocktail_api.dart';
import 'upload_api.dart';

/// 页面/Store 取得服务端接口的统一注入入口。
///
/// 页面建议由对应 Store 调用这些 Provider，避免在 Widget 内新建 Dio 或 API 实例。
final cocktailApiProvider = Provider<CocktailApi>((ref) => CocktailApi());

final uploadApiProvider = Provider<UploadApi>((ref) => UploadApi());
