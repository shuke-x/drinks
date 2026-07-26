import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 字体 tokens —— 对应设计稿字体链：
/// 中文标题 Noto Serif SC · 英文斜体 Playfair Display ·
/// 正文 Hanken Grotesk · 数字/计量 DM Mono
class AppType {
  AppType._();

  /// 中文衬线（标题/酒名）
  static TextStyle serifZh({
    double size = 16,
    FontWeight weight = FontWeight.w700,
    Color color = Colors.white,
    double height = 1.2,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.notoSerifSc(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  /// 英文斜体衬线（酒的英文名/风味故事）
  static TextStyle playfair({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double height = 1.0,
    FontStyle style = FontStyle.italic,
  }) =>
      GoogleFonts.playfairDisplay(
        fontSize: size,
        fontWeight: weight,
        fontStyle: style,
        color: color ?? Colors.white.withOpacity(.6),
        height: height,
      );

  /// 无衬线正文
  static TextStyle sans({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = Colors.white,
    double height = 1.35,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.hankenGrotesk(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  /// 等宽（ABV / 用量 / 版本号）
  static TextStyle mono({
    double size = 12,
    FontWeight weight = FontWeight.w500,
    Color color = Colors.white,
    double height = 1.0,
  }) =>
      GoogleFonts.dmMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );

  /// 小型全大写 eyebrow 标签（letter-spacing .14~.18em）
  static TextStyle eyebrow({
    double size = 12,
    Color? color,
    double tracking = .14,
  }) =>
      GoogleFonts.hankenGrotesk(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color ?? Colors.white.withOpacity(.45),
        letterSpacing: size * tracking,
        height: 1.0,
      );
}
