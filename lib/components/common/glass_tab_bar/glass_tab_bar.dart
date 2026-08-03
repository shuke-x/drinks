import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/interaction/app_feedback.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/l10n.dart';
import '../apple_liquid_glass_button/apple_liquid_glass_button.dart';
import '../apple_liquid_glass_tab_bar/apple_liquid_glass_tab_bar.dart';

class _TabItem {
  final String label;
  final PhosphorIconData icon;
  final PhosphorIconData iconFill;
  final String appleIcon;
  final String appleIconFill;
  const _TabItem({
    required this.label,
    required this.icon,
    required this.iconFill,
    required this.appleIcon,
    required this.appleIconFill,
  });
}

/// 底部悬浮毛玻璃胶囊 TabBar —— 原型规格：
/// bottom 26px 居中，blur(30)，rgba(255,255,255,.10) 填充，
/// 选中项 .20 填充 + .38 描边，弹簧过渡 400ms。
class GlassTabBar extends StatefulWidget {
  /// 创建根路由使用的自适应 Liquid Glass TabBar。
  ///
  /// [key] 用于在 Widget 树中标识并保留 TabBar 状态。
  const GlassTabBar({
    super.key,
    required this.current,
    required this.onSelect,
    this.width,
    this.height = 56,
  })  : assert(width == null || width >= 0),
        assert(height >= 44);

  /// 当前选中目标的零起始下标。
  final int current;

  /// 用户选择目标时返回其零起始下标；路由跳转由调用方处理。
  final ValueChanged<int> onSelect;

  /// 外部指定的 TabBar 宽度；省略时填充父级提供的横向约束。
  final double? width;

  /// TabBar 高度，默认 56pt，且不能小于 iOS 44pt 点击目标。
  final double height;

  @override
  State<GlassTabBar> createState() => _GlassTabBarState();
}

class _GlassTabBarState extends State<GlassTabBar> {
  int? _pressedIndex;
  bool _longPressed = false;

  List<_TabItem> _items(BuildContext context) => [
        _TabItem(
          label: context.l10n.home,
          icon: PhosphorIcons.compass(),
          iconFill: PhosphorIcons.compass(PhosphorIconsStyle.fill),
          appleIcon: 'house',
          appleIconFill: 'house.fill',
        ),
        _TabItem(
          label: context.l10n.next,
          icon: PhosphorIcons.sparkle(),
          iconFill: PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
          appleIcon: 'sparkles',
          appleIconFill: 'sparkles',
        ),
        _TabItem(
          label: context.l10n.cocktails,
          icon: PhosphorIcons.wine(),
          iconFill: PhosphorIcons.wine(PhosphorIconsStyle.fill),
          appleIcon: 'wineglass',
          appleIconFill: 'wineglass.fill',
        ),
        _TabItem(
          label: context.l10n.user,
          icon: PhosphorIcons.userCircle(),
          iconFill: PhosphorIcons.userCircle(PhosphorIconsStyle.fill),
          appleIcon: 'person.crop.circle',
          appleIconFill: 'person.crop.circle.fill',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final items = _items(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final highContrast = MediaQuery.highContrastOf(context);

    final contents = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: highContrast
            ? const Color(0xFF242229)
            : Colors.white.withValues(alpha: .10),
        border: Border.all(
          color: highContrast
              ? Colors.white.withValues(alpha: .48)
              : Colors.white.withValues(alpha: .18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .48),
            blurRadius: 38,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / items.length;
          final selectedIndex = widget.current.clamp(0, items.length - 1);
          return SizedBox(
            height: widget.height,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: reduceMotion ? Duration.zero : AppMotion.base,
                  curve: reduceMotion ? Curves.linear : AppMotion.standard,
                  left: segmentWidth * selectedIndex + 3,
                  top: 6,
                  bottom: 6,
                  width: segmentWidth - 6,
                  child: IgnorePointer(
                    child: AnimatedScale(
                      duration: reduceMotion ? Duration.zero : AppMotion.fast,
                      curve: reduceMotion ? Curves.linear : AppMotion.standard,
                      scale: _pressedIndex == selectedIndex
                          ? (_longPressed ? .91 : .965)
                          : 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          gradient: highContrast
                              ? null
                              : LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withValues(alpha: .31),
                                    Colors.white.withValues(alpha: .11),
                                  ],
                                ),
                          color: highContrast ? const Color(0xFF504D57) : null,
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: highContrast ? .72 : .38,
                            ),
                          ),
                          boxShadow: highContrast
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: .12),
                                    blurRadius: 14,
                                    offset: const Offset(0, -2),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: .16),
                                    blurRadius: 9,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: List.generate(items.length, (i) {
                      final item = items[i];
                      final active = i == selectedIndex;
                      final foreground = active
                          ? Colors.white
                          : Colors.white.withValues(
                              alpha: highContrast ? .76 : .55,
                            );
                      return Expanded(
                        child: Semantics(
                          button: true,
                          selected: active,
                          label: item.label,
                          child: GestureDetector(
                            key: ValueKey('tab_$i'),
                            excludeFromSemantics: true,
                            behavior: HitTestBehavior.opaque,
                            onTapDown: (_) => setState(() {
                              _pressedIndex = i;
                              _longPressed = false;
                            }),
                            onTapCancel: () => setState(() {
                              _pressedIndex = null;
                              _longPressed = false;
                            }),
                            onTapUp: (_) => setState(() {
                              _pressedIndex = null;
                              _longPressed = false;
                            }),
                            onLongPressStart: (_) {
                              setState(() {
                                _pressedIndex = i;
                                _longPressed = true;
                              });
                              AppFeedback.impact();
                            },
                            onLongPressEnd: (_) => setState(() {
                              _pressedIndex = null;
                              _longPressed = false;
                            }),
                            onTap: () {
                              if (i != selectedIndex) AppFeedback.selection();
                              widget.onSelect(i);
                            },
                            child: AnimatedScale(
                              duration:
                                  reduceMotion ? Duration.zero : AppMotion.fast,
                              curve: reduceMotion
                                  ? Curves.linear
                                  : AppMotion.standard,
                              scale: _pressedIndex == i
                                  ? (_longPressed ? .91 : .96)
                                  : 1,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: reduceMotion
                                          ? Duration.zero
                                          : AppMotion.fast,
                                      child: Icon(
                                        active ? item.iconFill : item.icon,
                                        key: ValueKey(active),
                                        size: 17,
                                        color: foreground,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        item.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.fade,
                                        softWrap: false,
                                        style: AppType.sans(
                                          size: 12.5,
                                          weight: FontWeight.w600,
                                          color: foreground,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final fallback = ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: highContrast
          ? contents
          : BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: contents,
            ),
    );
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AppleLiquidGlassSwitcher(
        fallback: fallback,
        nativeBuilder: (_) => AppleLiquidGlassTabBar(
          currentIndex: widget.current,
          onSelected: widget.onSelect,
          items: [
            for (final item in items)
              AppleLiquidGlassTabItem(
                label: item.label,
                systemImageName: item.appleIcon,
                selectedSystemImageName: item.appleIconFill,
              ),
          ],
        ),
      ),
    );
  }
}
