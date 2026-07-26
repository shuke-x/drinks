import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 间距 tokens（4pt 栅格；页面水平内边距 18 取自原型）
class AppSpacing {
  AppSpacing._();
  static const double gutter = 18;
  static const double tabBarBottom = 26;
}

class AppTheme {
  AppTheme._();

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bgBase,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          surface: AppColors.bgBase,
        ),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
      );
}
