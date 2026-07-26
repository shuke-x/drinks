import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/theme/app_effects.dart';
import '../core/theme/app_typography.dart';

class TabItem {
  final String label;
  final PhosphorIconData icon;
  final PhosphorIconData iconFill;
  const TabItem(
      {required this.label, required this.icon, required this.iconFill});
}

/// 底部悬浮毛玻璃胶囊 TabBar —— 原型规格：
/// bottom 26px 居中，blur(30)，rgba(255,255,255,.10) 填充，
/// 选中项 .20 填充 + .38 描边，弹簧过渡 400ms。
class GlassTabBar extends StatelessWidget {
  const GlassTabBar({super.key, required this.current, required this.onSelect});

  final int current;
  final ValueChanged<int> onSelect;

  static final items = [
    TabItem(
      label: 'Home',
      icon: PhosphorIcons.house(),
      iconFill: PhosphorIcons.house(PhosphorIconsStyle.fill),
    ),
    TabItem(
      label: 'Next',
      icon: PhosphorIcons.shuffle(),
      iconFill: PhosphorIcons.shuffle(PhosphorIconsStyle.fill),
    ),
    TabItem(
      label: 'System',
      icon: PhosphorIcons.sliders(),
      iconFill: PhosphorIcons.sliders(PhosphorIconsStyle.fill),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            color: Colors.white.withOpacity(.10),
            border: Border.all(color: Colors.white.withOpacity(.18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.5),
                blurRadius: 44,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(items.length, (i) {
              final it = items[i];
              final active = i == current;
              final fg = active ? Colors.white : Colors.white.withOpacity(.55);
              return GestureDetector(
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: AppMotion.spring,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 17, vertical: 11),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: active
                        ? Colors.white.withOpacity(.2)
                        : Colors.transparent,
                    border: Border.all(
                      color: active
                          ? Colors.white.withOpacity(.38)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(active ? it.iconFill : it.icon, size: 17, color: fg),
                    const SizedBox(width: 7),
                    Text(it.label,
                        style: AppType.sans(
                            size: 12.5,
                            weight: FontWeight.w600,
                            color: fg,
                            height: 1.0)),
                  ]),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
