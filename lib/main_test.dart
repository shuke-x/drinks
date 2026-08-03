import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';

import 'app.dart';

void main() {
  enableFlutterDriverExtension();
  runApp(const ProviderScope(child: TonightDrinksApp()));
}
