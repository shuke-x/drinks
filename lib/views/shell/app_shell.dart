import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../components/ambient_background.dart';
import '../../components/glass_tab_bar.dart';
import '../../components/palette.dart';
import '../../core/theme/app_effects.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../router/app_router.dart';
import '../../stores/settings_store.dart';

/// 应用外壳：三层结构（原型）：
/// 氛围光斑背景层 → 内容层（各 Tab 页）→ 悬浮控件层（TabBar / Toast）。
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ambient = ref.watch(ambientColorProvider);
    final location = GoRouterState.of(context).uri.path;
    final tabIndex = tabIndexOf(location);
    final toast = ref.watch(toastProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AmbientBackground(color: ambient),
          child,
          // 底部悬浮 TabBar（原型 bottom:26 居中）
          Positioned(
            left: 0,
            right: 0,
            bottom: AppSpacing.tabBarBottom,
            child: Center(
              child: GlassTabBar(
                current: tabIndex,
                onSelect: (i) {
                  const paths = ['/home', '/next', '/system'];
                  if (i != tabIndex) context.go(paths[i]);
                },
              ),
            ),
          ),
          // 顶部 Toast（原型 top:70 胶囊）
          Positioned(
            top: MediaQuery.paddingOf(context).top + 14,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: AnimatedSwitcher(
                duration: AppMotion.slow,
                switchInCurve: AppMotion.spring,
                transitionBuilder: (c, a) => SlideTransition(
                  position: Tween(
                    begin: const Offset(0, .4),
                    end: Offset.zero,
                  ).animate(a),
                  child: c,
                ),
                child: toast.isEmpty
                    ? const SizedBox.shrink()
                    : Center(
                        key: ValueKey(toast),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 13, sigmaY: 13),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 11),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(99),
                                color: Colors.white.withOpacity(.13),
                                border: Border.all(
                                    color: Colors.white.withOpacity(.2)),
                              ),
                              child: Text(
                                toast,
                                style: AppType.sans(
                                    size: 13,
                                    weight: FontWeight.w600,
                                    height: 1.0),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
