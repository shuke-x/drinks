import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../models/cocktail.dart';
import '../core/navigation/root_tab_bar_composition.dart';
import '../views/detail/detail_view.dart';
import '../views/home/home_view.dart';
import '../views/next/next_view.dart';
import '../views/shell/app_shell.dart';
import '../views/system/system_view.dart';
import '../views/upload/upload_view.dart';
import '../views/user/user_view.dart';
import '../views/user/profile_detail_view.dart';
import '../views/user/auth_gate_view.dart';
import '../views/favorites/favorites_view.dart';
import '../views/private/private_view.dart';

Page<void> _cupertinoSecondaryPage(GoRouterState state, Widget child) {
  return _SecondaryCupertinoPage<void>(
    key: state.pageKey,
    name: state.name,
    arguments: state.extra,
    child: child,
  );
}

/// An opaque secondary page that keeps Cupertino's interactive edge swipe.
///
/// The custom route also reports its lifecycle to the retained root tab bar.
class _SecondaryCupertinoPage<T> extends Page<T> {
  const _SecondaryCupertinoPage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
  });

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) =>
      _SecondaryCupertinoPageRoute<T>(page: this);
}

class _SecondaryCupertinoPageRoute<T> extends PageRoute<T>
    with CupertinoRouteTransitionMixin<T> {
  _SecondaryCupertinoPageRoute({
    required _SecondaryCupertinoPage<T> page,
  }) : super(settings: page);

  _SecondaryCupertinoPage<T> get _page =>
      settings as _SecondaryCupertinoPage<T>;

  bool _countedAsOverlay = false;

  void _markPresented() {
    if (_countedAsOverlay) return;
    _countedAsOverlay = true;
    RootTabBarComposition.overlayDidPresent();
  }

  void _markDismissed() {
    if (!_countedAsOverlay) return;
    _countedAsOverlay = false;
    RootTabBarComposition.overlayDidDismiss();
  }

  @override
  TickerFuture didPush() {
    _markPresented();
    return super.didPush();
  }

  @override
  void didAdd() {
    _markPresented();
    super.didAdd();
  }

  @override
  bool didPop(T? result) {
    final popped = super.didPop(result);
    if (!popped) return false;
    // A successful pop cannot be cancelled anymore. Reveal the retained root
    // tab bar now so it is part of the primary page exposed by the outgoing
    // Cupertino transition, instead of adding a frame after dismissal.
    _markDismissed();
    return true;
  }

  @override
  void dispose() {
    _markDismissed();
    super.dispose();
  }

  @override
  bool get opaque => true;

  @override
  Color? get barrierColor => null;

  @override
  bool get maintainState => true;

  @override
  String? get title => null;

  @override
  Widget buildContent(BuildContext context) => _page.child;
}

/// 主 Tab 是同一内容区域的替换，不使用透明路由动画。
///
/// Tab 页面没有自己的不透明底色，若用 [FadeTransition]，动画期间会露出
/// Navigator 中尚未移除的旧页面，造成两页内容重叠的观感。详情和上传改
/// 由不透明且支持侧滑返回的 Cupertino 路由承载。
NoTransitionPage<void> _tabPage(GoRouterState state, Widget child) {
  return NoTransitionPage<void>(
    key: state.pageKey,
    child: child,
  );
}

final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(
        tabIndex: tabIndexOf(state.uri.path),
        child: child,
      ),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => _tabPage(state, const HomeView()),
        ),
        GoRoute(
          path: '/next',
          pageBuilder: (context, state) => _tabPage(state, const NextView()),
        ),
        GoRoute(
          path: '/private',
          pageBuilder: (context, state) => _tabPage(state, const PrivateView()),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => _tabPage(state, const UserView()),
        ),
      ],
    ),
    // 详情：不透明二级页，不透出底层页面。
    GoRoute(
      path: '/detail/:id',
      pageBuilder: (context, state) => _cupertinoSecondaryPage(
        state,
        DetailView(
          id: state.pathParameters['id']!,
          initialDrink:
              state.extra is Cocktail ? state.extra! as Cocktail : null,
          allowEditing: state.uri.queryParameters['editable'] == 'true',
        ),
      ),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => _cupertinoSecondaryPage(
        state,
        const AuthGateView(),
      ),
    ),
    GoRoute(
      path: '/profile-detail',
      pageBuilder: (context, state) =>
          _cupertinoSecondaryPage(state, const ProfileDetailView()),
    ),
    GoRoute(
      path: '/favorites',
      pageBuilder: (context, state) =>
          _cupertinoSecondaryPage(state, const FavoritesView()),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) =>
          _cupertinoSecondaryPage(state, const SystemView()),
    ),
    // 上传 / 编辑：?edit=<id>
    GoRoute(
      path: '/upload',
      pageBuilder: (context, state) => _cupertinoSecondaryPage(
        state,
        UploadView(
          editId: state.uri.queryParameters['edit'],
          privateByDefault:
              state.uri.queryParameters['private'] == 'true' ? true : null,
          initialDrink:
              state.extra is Cocktail ? state.extra! as Cocktail : null,
        ),
      ),
    ),
  ],
);

/// 由路由路径得出当前 Tab 下标。
int tabIndexOf(String location) {
  if (location.startsWith('/next')) return 1;
  if (location.startsWith('/private')) return 2;
  if (location.startsWith('/profile')) return 3;
  return 0;
}
