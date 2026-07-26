import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_effects.dart';
import '../views/detail/detail_view.dart';
import '../views/home/home_view.dart';
import '../views/next/next_view.dart';
import '../views/shell/app_shell.dart';
import '../views/system/system_view.dart';
import '../views/upload/upload_view.dart';

/// 页面 fadeUp 过渡（原型 fadeUp：透明度 + 上滑 12px，450ms 标准缓动）。
CustomTransitionPage<void> _fadeUpPage(GoRouterState state, Widget child,
    {bool opaque = true}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    opaque: opaque,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 450),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondary, child) {
      final t = CurvedAnimation(parent: animation, curve: AppMotion.standard);
      return SlideTransition(
        position:
            Tween(begin: const Offset(0, 0.014), end: Offset.zero).animate(t),
        child: child,
      );
    },
    child: child,
  );
}

/// 上传表单从右侧以卡片形式推入。
///
/// 不使用透明度动画，避免透明覆盖页在进场前半段露出底页内容；时长和缓动
/// 前段缓慢推进，约 70% 后加速完成，强调表单卡片的落位。
CustomTransitionPage<void> _slideInFromRightPage(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    opaque: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 420),
    transitionsBuilder: (context, animation, secondary, child) {
      final t = CurvedAnimation(
        parent: animation,
        curve: AppMotion.lateAcceleration,
        reverseCurve: Curves.linear,
      );
      return SlideTransition(
        position: Tween(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(t),
        child: child,
      );
    },
    child: child,
  );
}

/// 主 Tab 是同一内容区域的替换，不使用透明路由动画。
///
/// Tab 页面没有自己的不透明底色，若用 [FadeTransition]，动画期间会露出
/// Navigator 中尚未移除的旧页面，造成两页内容重叠的观感。详情和上传是
/// 有意保留底页的覆盖层，仍使用 [_fadeUpPage]。
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
      builder: (context, state, child) => AppShell(child: child),
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
          path: '/system',
          pageBuilder: (context, state) => _tabPage(state, const SystemView()),
        ),
      ],
    ),
    // 详情：全屏毛玻璃覆盖层（透明路由，底下页面保留）。
    GoRoute(
      path: '/detail/:id',
      pageBuilder: (context, state) => _fadeUpPage(
        state,
        DetailView(id: state.pathParameters['id']!),
        opaque: false,
      ),
    ),
    // 上传 / 编辑：?edit=<id>
    GoRoute(
      path: '/upload',
      pageBuilder: (context, state) => _slideInFromRightPage(
        state,
        UploadView(editId: state.uri.queryParameters['edit']),
      ),
    ),
  ],
);

/// 由路由路径得出当前 Tab 下标。
int tabIndexOf(String location) {
  if (location.startsWith('/next')) return 1;
  if (location.startsWith('/system')) return 2;
  return 0;
}
