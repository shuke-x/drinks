import 'package:flutter/material.dart';

import '../core/theme/app_typography.dart';
import 'glass.dart';

/// 通用空状态：请求成功但没有可显示的数据时使用，区别于加载中的莫比乌斯环。
class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .08),
              border: Border.all(color: Colors.white.withValues(alpha: .14)),
            ),
            child: Icon(icon,
                size: 24, color: Colors.white.withValues(alpha: .62)),
          ),
          const SizedBox(height: 14),
          Text(title, style: AppType.serifZh(size: 17)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppType.sans(
              size: 12.5,
              color: Colors.white.withValues(alpha: .45),
              height: 1.5,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            GlassActionButton(label: actionLabel!, onTap: onAction),
          ],
        ]),
      ),
    );
  }
}
