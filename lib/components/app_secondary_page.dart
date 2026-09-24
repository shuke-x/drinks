import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_typography.dart';
import 'common/glass_circle_button/glass_circle_button.dart';
import 'frosted_page_overlay.dart';

/// Shared secondary-page structure for iOS-style back navigation and toolbar
/// actions. Page content starts below the safe-area toolbar.
class AppSecondaryPage extends StatelessWidget {
  const AppSecondaryPage({
    super.key,
    required this.title,
    required this.child,
    this.onBack,
    this.fallbackLocation = '/profile',
    this.actions = const [],
  });

  final String title;
  final Widget child;
  final VoidCallback? onBack;
  final String fallbackLocation;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => FrostedPageOverlay(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: 56,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 12, 4),
                    child: Row(
                      children: [
                        GlassCircleButton(
                          key: const ValueKey('secondary_back'),
                          icon: CupertinoIcons.chevron_back,
                          appleSystemImageName: 'chevron.left',
                          size: 38,
                          iconSize: 17,
                          semanticLabel: MaterialLocalizations.of(context)
                              .backButtonTooltip,
                          onTap: onBack ??
                              () => context.canPop()
                                  ? context.pop()
                                  : context.go(fallbackLocation),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.serifZh(size: 20),
                          ),
                        ),
                        if (actions.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          ...actions,
                        ],
                      ],
                    ),
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      );
}
