import 'package:flutter/material.dart';

import '../../components/app_secondary_page.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/l10n.dart';

/// Factual product disclosure; final operator policies remain a release task.
class PrivacyView extends StatelessWidget {
  const PrivacyView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sections = [
      (l10n.responsibleUseTitle, l10n.responsibleUseBody),
      (l10n.privacyDataTitle, l10n.privacyDataBody),
      (l10n.privacyPhotosTitle, l10n.privacyPhotosBody),
      (l10n.privacyDiagnosticsTitle, l10n.privacyDiagnosticsBody),
      (l10n.privacyAccountTitle, l10n.privacyAccountBody),
      (l10n.privacyPendingTitle, l10n.privacyPendingBody),
    ];
    return AppSecondaryPage(
      title: l10n.privacyAndUse,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 28),
        itemBuilder: (context, index) {
          final (title, body) = sections[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(title,
                    style: AppType.sans(size: 18, weight: FontWeight.w600)),
              ),
              const SizedBox(height: 10),
              if (index == sections.length - 1)
                SelectableText(body, style: AppType.sans(size: 16, height: 1.6))
              else
                Text(body, style: AppType.sans(size: 16, height: 1.6)),
            ],
          );
        },
      ),
    );
  }
}
