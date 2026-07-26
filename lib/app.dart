import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'router/app_router.dart';

class TonightDrinksApp extends StatelessWidget {
  const TonightDrinksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '今晚喝什么',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      routerConfig: appRouter,
    );
  }
}
