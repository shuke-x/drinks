import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_effects.dart';
import '../core/theme/app_typography.dart';
import '../stores/settings_store.dart';

/// 放在 Navigator 外层，确保登录、详情及主 Tab 都能显示同一个顶部气泡。
class AppToastOverlay extends ConsumerWidget {
  const AppToastOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.watch(toastProvider);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned(
          top: MediaQuery.paddingOf(context).top + 14,
          left: 16,
          right: 16,
          child: IgnorePointer(
            child: AnimatedSwitcher(
              duration: AppMotion.base,
              switchInCurve: AppMotion.spring,
              switchOutCurve: AppMotion.easeOut,
              transitionBuilder: (child, animation) => reduceMotion
                  ? FadeTransition(opacity: animation, child: child)
                  : SlideTransition(
                      position: Tween(
                        begin: const Offset(0, -.35),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    ),
              child: toast.isEmpty
                  ? const SizedBox.shrink()
                  : Center(
                      key: ValueKey(toast),
                      child: Semantics(
                        container: true,
                        liveRegion: true,
                        label: toast,
                        child: ExcludeSemantics(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 13, sigmaY: 13),
                              child: Container(
                                constraints:
                                    const BoxConstraints(maxWidth: 420),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(99),
                                  color: const Color(0xE62B2930),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: .24),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x66000000),
                                      blurRadius: 30,
                                      offset: Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  toast,
                                  textAlign: TextAlign.center,
                                  style: AppType.sans(
                                    size: 13,
                                    weight: FontWeight.w600,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
