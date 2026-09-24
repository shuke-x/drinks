import 'package:flutter/material.dart';

/// 颜色 tokens —— 提取自设计稿 tokens/colors.css 与原型内联样式。
class AppColors {
  AppColors._();

  // ---- 基底 ----
  /// 手机屏内基底（原型 frame 背景 #0D0B10）
  static const Color bgBase = Color(0xFF0D0B10);

  // ---- 文字 ----
  static const Color textPrimary = Color(0xFFFFFFFF);
  static Color textSecondary = const Color(0xFFFFFFFF).withValues(alpha: .62);
  static Color text45 = const Color(0xFFFFFFFF).withValues(alpha: .45);
  static Color text50 = const Color(0xFFFFFFFF).withValues(alpha: .50);
  static Color text42 = const Color(0xFFFFFFFF).withValues(alpha: .42);

  // ---- 毛玻璃表面（原型内联值）----
  static Color glassFill08 = const Color(0xFFFFFFFF).withValues(alpha: .08);
  static Color glassFill09 = const Color(0xFFFFFFFF).withValues(alpha: .09);
  static Color glassFill10 = const Color(0xFFFFFFFF).withValues(alpha: .10);
  static Color glassFill11 = const Color(0xFFFFFFFF).withValues(alpha: .11);
  static Color glassBorder = const Color(0xFFFFFFFF).withValues(alpha: .15);
  static Color glassBorder12 = const Color(0xFFFFFFFF).withValues(alpha: .12);
  static Color glassBorderStrong =
      const Color(0xFFFFFFFF).withValues(alpha: .20);
  static Color hairline = const Color(0xFFFFFFFF).withValues(alpha: .08);

  // ---- 语义色（tokens/colors.css）----
  static const Color danger = Color(0xFFFF453A);
  static const Color info = Color(0xFF0A84FF);

  // ---- 特殊 ----
  /// 抽中卡片的金色光晕（原型：rgba(201,162,39,·)）
  static const Color gold = Color(0xFFC9A227);

  /// System 页主题色（原型 themeColor()）
  static const Color systemAccent = Color(0xFF5E5CE6);

  // ---- 账户认证主题色（Apple 深色模式的低饱和系统蓝）----
  static const Color brand1 = Color(0xFF0A84FF);
  static const Color brand2 = Color(0xFF0A84FF);
  static const Color brand3 = Color(0xFF5E5CE6);
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brand1, brand3],
  );
  static const BoxShadow shadowAccent = BoxShadow(
    color: Color(0x550A84FF),
    blurRadius: 24,
    offset: Offset(0, 10),
  );

  /// 上传表单主题色候选（原型 SWATCH）
  static const List<Color> swatch = [
    Color(0xFF0A84FF),
    Color(0xFF30D158),
    Color(0xFFFF9F0A),
    Color(0xFFFF453A),
    Color(0xFFBF5AF2),
    Color(0xFF64D2FF),
  ];
}
