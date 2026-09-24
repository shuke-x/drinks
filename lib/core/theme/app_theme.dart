import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 应用间距 tokens；页面内容与悬浮导航使用独立配置。
class AppSpacing {
  AppSpacing._();

  /// 页面内容与屏幕左右边缘的通用间距。
  static const double gutter = 12;

  /// 【TabBar 横向位置】悬浮 TabBar 与屏幕左右边缘的独立距离。
  ///
  /// 不要复用 [gutter]：页面内容间距与底部导航宽度应可分别调整。
  static const double tabBarHorizontal = 12;

  /// 【TabBar 底部位置】安全区上方额外保留的视觉间距。
  static const double tabBarBottom = 10;
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
