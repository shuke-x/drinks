import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../components/frosted_page_overlay.dart';
import '../../components/glass.dart';
import '../../core/theme/app_effects.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../stores/settings_store.dart';
import '../../l10n/l10n.dart';

/// 精简后的设置页：只保留配方的计量单位与换算相关设置。
class SystemView extends ConsumerWidget {
  const SystemView({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider);
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: FrostedPageOverlay(
            child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    AppSpacing.gutter, top + 16, AppSpacing.gutter, 42),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlassCircleButton(
                          icon: PhosphorIcons.arrowLeft(),
                          appleSystemImageName: 'chevron.left',
                          size: 38,
                          iconSize: 17,
                          semanticLabel: MaterialLocalizations.of(context)
                              .backButtonTooltip,
                          onTap: () => context.pop()),
                      const SizedBox(height: 22),
                      Text(context.l10n.unitsAndCalculation,
                          style: AppType.serifZh(size: 28)),
                      const SizedBox(height: 5),
                      Text(context.l10n.unitSettingsSubtitle,
                          style: AppType.sans(
                              size: 13,
                              color: Colors.white.withValues(alpha: .5))),
                      const SizedBox(height: 22),
                      GlassCard(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(context.l10n.measurementUnit,
                                style: AppType.eyebrow()),
                            const SizedBox(height: 15),
                            Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(99),
                                    color: const Color(0xFF787880)
                                        .withValues(alpha: .32)),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _unit(ref, 'ml', data.unit == 'ml'),
                                      _unit(ref, 'oz', data.unit == 'oz')
                                    ])),
                            const SizedBox(height: 16),
                            Text(
                                data.unit == 'ml'
                                    ? context.l10n.milliliterMode
                                    : context.l10n.ounceMode,
                                style: AppType.sans(
                                    size: 12.5,
                                    color: Colors.white.withValues(alpha: .5),
                                    height: 1.5))
                          ])),
                    ]))));
  }

  Widget _unit(WidgetRef ref, String label, bool active) => GestureDetector(
      onTap: () => ref.read(appDataProvider.notifier).setUnit(label),
      child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: AppMotion.spring,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              color: active
                  ? Colors.white.withValues(alpha: .94)
                  : Colors.transparent),
          child: Text(label,
              style: AppType.mono(
                  size: 12,
                  color: active
                      ? const Color(0xFF0D0B10)
                      : Colors.white.withValues(alpha: .6)))));
}
