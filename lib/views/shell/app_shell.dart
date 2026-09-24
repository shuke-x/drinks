import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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

  // Tab 的页面内容/跳转地址在这里改。
  // 注意：数组顺序必须和 GlassTabBar._items 中的项目顺序保持一致。
  static const _loggedInTabLocations = [
    '/home',
    '/recommend',
    '/recipes',
    '/profile',
  ];
  static const _guestTabLocations = [
    '/home',
    '/recommend',
    '/recipes',
    '/profile',
  ];
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ambient = ref.watch(ambientColorProvider);
    final isLoggedIn = ref.watch(
      userProvider.select((state) => state.isLoggedIn),
    );
    final tabLocations =
        isLoggedIn ? _loggedInTabLocations : _guestTabLocations;
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
          // 【TabBar 位置】修改 left/right 可调左右留白；修改 bottom 可调底部距离。
          // AppSpacing 中集中存放这些尺寸，并叠加安全区以避开 Home Indicator。
          Positioned(
            left: AppSpacing.tabBarHorizontal,
            right: AppSpacing.tabBarHorizontal,
            bottom:
                AppSpacing.tabBarBottom + MediaQuery.paddingOf(context).bottom,
            child: _PrimaryRouteTabBar(
              current: tabIndex,
              showCocktails: true,
              onSearch: null,
              onSelect: (i) {
                AppFeedback.selection();
                context.go(tabLocations[i]);
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
    required this.showCocktails,
    required this.onSearch,
  });

  final int current;
  final ValueChanged<int> onSelect;
  final bool showCocktails;
  final VoidCallback? onSearch;

  @override
  State<_PrimaryRouteTabBar> createState() => _PrimaryRouteTabBarState();
}

class _PrimaryRouteTabBarState extends State<_PrimaryRouteTabBar> {
  // 【TabBar 尺寸】主 TabBar、游客搜索按钮和两者间距在这里改。
  static const double _tabBarHeight = 56;
  static const double _searchButtonSize = 56;
  static const double _guestControlGap = 10;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: RootTabBarComposition.visible,
        builder: (context, visible, _) => IgnorePointer(
          ignoring: !visible,
          child: Offstage(
            offstage: !visible,
            child: TickerMode(
              enabled: visible,
              child: Row(
                children: [
                  Expanded(
                    // 【TabBar 组件入口】文案/图标/选中样式在 GlassTabBar 内修改。
                    child: GlassTabBar(
                      current: widget.current,
                      onSelect: widget.onSelect,
                      showCocktails: widget.showCocktails,
                      height: _tabBarHeight,
                    ),
                  ),
                  if (widget.onSearch != null) ...[
                    // 游客状态下，搜索是 TabBar 右侧的独立按钮，不属于 Tab 项。
                    const SizedBox(width: _guestControlGap),
                    GlassActionButton(
                      key: const ValueKey('guest_search_action'),
                      label: context.l10n.search,
                      icon: PhosphorIcons.magnifyingGlass(),
                      appleSystemImageName: 'magnifyingglass',
                      showLabel: false,
                      width: _searchButtonSize,
                      height: _searchButtonSize,
                      onTap: widget.onSearch,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
}
