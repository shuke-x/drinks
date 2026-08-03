import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../components/ambient_background.dart';
import '../../components/common/common.dart';
import '../../components/palette.dart';
import '../../core/interaction/app_feedback.dart';
import '../../core/navigation/root_tab_bar_composition.dart';
import '../../core/theme/app_theme.dart';
import '../../stores/settings_store.dart';
import '../../stores/user_store.dart';
import '../../l10n/l10n.dart';

/// 应用外壳：三层结构（原型）：
/// 氛围光斑背景层 → 内容层（各 Tab 页）→ 悬浮控件层（TabBar / Toast）。
class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.child,
    required this.tabIndex,
  });

  final Widget child;
  final int tabIndex;

  static const _tabLocations = ['/home', '/next', '/private', '/profile'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ambient = ref.watch(ambientColorProvider);
    ref.watch(userProvider.select((state) => state.sessionExpiredEvent));
    ref.listen<UserState>(userProvider, (previous, next) {
      if (next.sessionExpiredEvent > (previous?.sessionExpiredEvent ?? 0)) {
        ref.read(toastProvider.notifier).show(context.l10n.sessionExpired);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.go('/home');
        });
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AmbientBackground(color: ambient),
          child,
          // 底部悬浮 TabBar：贴近安全区，同时避开 Home Indicator。
          Positioned(
            left: 20,
            right: 20,
            bottom:
                AppSpacing.tabBarBottom + MediaQuery.paddingOf(context).bottom,
            child: _PrimaryRouteTabBar(
              current: tabIndex,
              onSelect: (i) {
                AppFeedback.selection();
                context.go(_tabLocations[i]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Keeps the native tab bar out of transparent secondary-route composition.
///
/// The tab bar stays mounted while a secondary route is visible. This keeps
/// the same UIKit platform view alive across push/pop and avoids the fallback
/// frame that would otherwise appear while a new native view is being made.
class _PrimaryRouteTabBar extends StatefulWidget {
  const _PrimaryRouteTabBar({
    required this.current,
    required this.onSelect,
  });

  final int current;
  final ValueChanged<int> onSelect;

  @override
  State<_PrimaryRouteTabBar> createState() => _PrimaryRouteTabBarState();
}

class _PrimaryRouteTabBarState extends State<_PrimaryRouteTabBar> {
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: RootTabBarComposition.visible,
        builder: (context, visible, _) => IgnorePointer(
          ignoring: !visible,
          child: Offstage(
            offstage: !visible,
            child: TickerMode(
              enabled: visible,
              child: GlassTabBar(
                current: widget.current,
                onSelect: widget.onSelect,
              ),
            ),
          ),
        ),
      );
}
