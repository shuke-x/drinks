import 'package:flutter/material.dart';

import '../core/theme/app_typography.dart';
import 'glass.dart';

Future<T?> showContentDialog<T>({
  required BuildContext context,
  required Widget content,
  String? title,
  IconData? icon,
  List<Widget> actions = const [],
}) =>
    showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: .72),
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: const Cubic(.62, 0, .82, .18),
          reverseCurve: const Cubic(.18, .82, .38, 1),
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: .94, end: 1).animate(curved),
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) => Center(
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 520,
              maxHeight: MediaQuery.sizeOf(context).height * .82,
            ),
            child: GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    if (icon != null) ...[
                      Icon(icon, size: 25, color: Colors.white),
                      const SizedBox(height: 14),
                    ],
                    Text(title, style: AppType.serifZh(size: 21, height: 1.25)),
                    const SizedBox(height: 12),
                  ],
                  Flexible(child: content),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        for (var i = 0; i < actions.length; i++) ...[
                          if (i > 0) const SizedBox(width: 10),
                          Expanded(child: actions[i]),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
