import 'package:flutter/foundation.dart';

/// Keeps the root native tab bar out of transparent secondary-route layers.
class RootTabBarComposition {
  RootTabBarComposition._();

  static final ValueNotifier<bool> visible = ValueNotifier<bool>(true);
  static int _overlayDepth = 0;

  static void overlayDidPresent() {
    _overlayDepth += 1;
    if (visible.value) visible.value = false;
  }

  static void overlayDidDismiss() {
    if (_overlayDepth > 0) _overlayDepth -= 1;
    if (_overlayDepth == 0 && !visible.value) visible.value = true;
  }
}
