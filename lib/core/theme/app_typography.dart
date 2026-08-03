import 'package:flutter/material.dart';

/// 字体 tokens —— 对应设计稿字体链：
/// 中文标题 Noto Serif SC · 英文斜体 Playfair Display ·
/// 正文 Hanken Grotesk · 数字/计量 DM Mono
class AppType {
  AppType._();

  /// 语义化展示标题：全局只在这里维护 Fraunces 的标题规格。
  static TextStyle title({
    double size = 28,
    FontWeight weight = FontWeight.w700,
    Color color = Colors.white,
    double height = 1.2,
  }) =>
      TextStyle(
        fontFamily: 'Fraunces',
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        decoration: TextDecoration.none,
        decorationColor: Colors.transparent,
      );

  /// 语义化提示：辅助信息统一使用低强调正文规格。
  static TextStyle tips({
    double size = 13,
    Color? color,
    double height = 1.35,
  }) =>
      TextStyle(
        fontFamily: 'HankenGrotesk',
        fontSize: size,
        fontWeight: FontWeight.w400,
        color: color ?? Colors.white.withValues(alpha: .55),
        height: height,
        decoration: TextDecoration.none,
        decorationColor: Colors.transparent,
      );

  /// 中文衬线（标题/酒名）
  static TextStyle serifZh({
    double size = 16,
    FontWeight weight = FontWeight.w700,
    Color color = Colors.white,
    double height = 1.2,
    double letterSpacing = 0,
  }) =>
      TextStyle(
        fontFamily: 'NotoSerifSC',
        fontFamilyFallback: const ['serif'],
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        decoration: TextDecoration.none,
        decorationColor: Colors.transparent,
      );

  /// 英文斜体衬线（酒的英文名/风味故事）
  static TextStyle playfair({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double height = 1.0,
    FontStyle style = FontStyle.italic,
  }) =>
      TextStyle(
        fontFamily: 'PlayfairDisplay',
        fontSize: size,
        fontWeight: weight,
        fontStyle: style,
        color: color ?? Colors.white.withValues(alpha: .6),
        height: height,
        decoration: TextDecoration.none,
        decorationColor: Colors.transparent,
      );

  /// 酒的英文名称固定使用 Fraunces 花体，不受字号阈值影响。
  static TextStyle cocktailEnglish({
    double size = 16,
    FontWeight weight = FontWeight.w600,
    Color? color,
    double height = 1.05,
  }) =>
      TextStyle(
        fontFamily: 'Fraunces',
        fontSize: size,
        fontWeight: weight,
        fontStyle: FontStyle.italic,
        color: color ?? Colors.white.withValues(alpha: .72),
        height: height,
        decoration: TextDecoration.none,
        decorationColor: Colors.transparent,
      );

  /// 无衬线正文
  static TextStyle sans({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = Colors.white,
    double height = 1.35,
    double letterSpacing = 0,
  }) =>
      TextStyle(
        fontFamily: 'HankenGrotesk',
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        decoration: TextDecoration.none,
        decorationColor: Colors.transparent,
      );

  /// 等宽（ABV / 用量 / 版本号）
  static TextStyle mono({
    double size = 12,
    FontWeight weight = FontWeight.w500,
    Color color = Colors.white,
    double height = 1.0,
  }) =>
      TextStyle(
        fontFamily: 'DMMono',
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        decoration: TextDecoration.none,
        decorationColor: Colors.transparent,
      );

  /// 小型全大写 eyebrow 标签（letter-spacing .14~.18em）
  static TextStyle eyebrow({
    double size = 12,
    Color? color,
    double tracking = .14,
  }) =>
      TextStyle(
        fontFamily: 'HankenGrotesk',
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color ?? Colors.white.withValues(alpha: .45),
        letterSpacing: size * tracking,
        height: 1.0,
        decoration: TextDecoration.none,
        decorationColor: Colors.transparent,
      );
}
