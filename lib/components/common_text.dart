import 'package:flutter/material.dart';

import '../core/theme/app_typography.dart';

/// 语义化标题层级；样式集中在这里，避免页面分散维护字号与字体。
enum AppTitleLevel { hero, page, section, card }

class AppTitle extends StatelessWidget {
  const AppTitle(
    this.data, {
    super.key,
    this.level = AppTitleLevel.page,
    this.color = Colors.white,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String data;
  final AppTitleLevel level;
  final Color color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final spec = switch (level) {
      AppTitleLevel.hero => (size: 33.0, height: 1.22),
      AppTitleLevel.page => (size: 28.0, height: 1.2),
      AppTitleLevel.section => (size: 20.0, height: 1.25),
      AppTitleLevel.card => (size: 16.0, height: 1.3),
    };
    return Text(data,
        style:
            AppType.title(size: spec.size, height: spec.height, color: color),
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow);
  }
}

/// 语义化辅助提示；统一弱化色、字重与行高。
class AppTips extends StatelessWidget {
  const AppTips(
    this.data, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String data;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) => Text(data,
      style: AppType.tips(color: color),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow);
}
