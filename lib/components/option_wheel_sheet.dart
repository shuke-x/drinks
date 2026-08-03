import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/interaction/app_feedback.dart';
import '../core/theme/app_typography.dart';
import 'common/apple_liquid_glass_button/apple_liquid_glass_button.dart';

@immutable
class OptionWheelItem<T> {
  const OptionWheelItem({required this.value, required this.label});

  final T value;
  final String label;
}

class OptionWheelButton extends StatelessWidget {
  const OptionWheelButton({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.onPressed,
    this.widthFactor = .5,
    this.controlKey,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final double widthFactor;
  final Key? controlKey;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: widthFactor,
        child: Semantics(
          button: true,
          enabled: onPressed != null,
          label: semanticLabel,
          value: label,
          excludeSemantics: true,
          child: SizedBox(
            key: controlKey,
            height: 44,
            child: AppleLiquidGlassSwitcher(
              nativeBuilder: (_) => AppleLiquidGlassButton(
                onPressed: onPressed,
                label: label,
                semanticLabel: semanticLabel,
                systemImageName: 'chevron.down',
                imagePadding: 6,
                imageTrailing: true,
                spreadContent: true,
              ),
              fallback: CupertinoButton(
                minimumSize: const Size(0, 44),
                padding: EdgeInsets.zero,
                onPressed: onPressed,
                child: Container(
                  width: double.infinity,
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: .15),
                        Colors.white.withValues(alpha: .07),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.sans(
                            size: 14,
                            weight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        key: ValueKey('option_wheel_disclosure_icon'),
                        CupertinoIcons.arrow_down,
                        size: 16,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

/// iOS-style option wheel shared by language and form classifications.
Future<T?> showOptionWheel<T>({
  required BuildContext context,
  required String title,
  required String cancelLabel,
  required String doneLabel,
  required List<OptionWheelItem<T>> options,
  required T selectedValue,
}) async {
  if (options.isEmpty) return null;
  var pendingIndex = options.indexWhere(
    (option) => option.value == selectedValue,
  );
  if (pendingIndex < 0) pendingIndex = 0;
  final wheelController = FixedExtentScrollController(
    initialItem: pendingIndex,
  );
  final value = await showCupertinoModalPopup<T>(
    context: context,
    useRootNavigator: true,
    builder: (sheetContext) => CupertinoTheme(
      data: const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.white,
      ),
      child: CupertinoPopupSurface(
        blurSigma: 0,
        isSurfacePainted: false,
        child: ColoredBox(
          key: const ValueKey('option_wheel_opaque_surface'),
          color: const Color(0xFF151218),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 304,
              child: Column(
                children: [
                  SizedBox(
                    height: 52,
                    child: Row(
                      children: [
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          child: Text(
                            cancelLabel,
                            style: AppType.sans(
                              size: 15,
                              weight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            style: AppType.sans(
                              size: 15,
                              weight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          onPressed: () => Navigator.of(sheetContext).pop(
                            options[pendingIndex].value,
                          ),
                          child: Text(
                            doneLabel,
                            style: AppType.sans(
                              size: 15,
                              weight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: Colors.white.withValues(alpha: .12),
                  ),
                  Expanded(
                    child: CupertinoPicker.builder(
                      scrollController: wheelController,
                      itemExtent: 44,
                      useMagnifier: true,
                      magnification: 1.08,
                      squeeze: 1.08,
                      selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                        background: Colors.white.withValues(alpha: .09),
                      ),
                      onSelectedItemChanged: (index) {
                        pendingIndex = index;
                        AppFeedback.selection();
                      },
                      childCount: options.length,
                      itemBuilder: (context, index) => Center(
                        child: Text(
                          options[index].label,
                          style: AppType.sans(
                            size: 17,
                            weight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  wheelController.dispose();
  return value;
}
