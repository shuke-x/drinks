import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'common/glass_circle_button/glass_circle_button.dart';

class PhotoPickerTile extends StatelessWidget {
  const PhotoPickerTile({
    super.key,
    required this.child,
    required this.onRemove,
    required this.semanticLabel,
    this.size = 72,
  });

  final Widget child;
  final VoidCallback onRemove;
  final String semanticLabel;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: child),
            Positioned(
              top: -2,
              right: -2,
              child: GlassCircleButton(
                icon: CupertinoIcons.xmark,
                appleSystemImageName: 'xmark',
                size: 20,
                iconSize: 10,
                semanticLabel: semanticLabel,
                onTap: onRemove,
              ),
            ),
          ],
        ),
      );
}

/// Shared image selection grid used by records and cocktail forms.
class PhotoPickerGrid extends StatelessWidget {
  const PhotoPickerGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.onAdd,
    this.maxItems = 9,
    this.itemSize = 72,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final VoidCallback onAdd;
  final int maxItems;
  final double itemSize;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < itemCount; i++) itemBuilder(context, i),
          if (itemCount < maxItems)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onAdd,
              child: Container(
                width: itemSize,
                height: itemSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withValues(alpha: .10),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: .22)),
                ),
                child: const Icon(
                  CupertinoIcons.photo_on_rectangle,
                  color: Colors.white70,
                ),
              ),
            ),
        ],
      );
}
