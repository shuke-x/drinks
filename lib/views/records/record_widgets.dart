import 'package:flutter/material.dart';

import '../../components/app_secondary_page.dart';
import '../../models/drink_record.dart';

String recordText(BuildContext context, String zh, String en) =>
    Localizations.localeOf(context).languageCode == 'en' ? en : zh;

String sceneLabel(BuildContext context, DrinkingScene scene) =>
    scene == DrinkingScene.home
        ? recordText(context, '自己调的', 'Made at home')
        : recordText(context, '在外喝的', 'Out for a drink');

String verdictLabel(BuildContext context, DrinkVerdict verdict) =>
    switch (verdict) {
      DrinkVerdict.loved => recordText(context, '很喜欢', 'Loved it'),
      DrinkVerdict.liked => recordText(context, '还不错', 'Liked it'),
      DrinkVerdict.notForMe => recordText(context, '不太适合我', 'Not for me'),
    };

class RecordPage extends StatelessWidget {
  const RecordPage(
      {super.key,
      required this.title,
      required this.child,
      this.onBack,
      this.actions = const []});
  final String title;
  final Widget child;
  final VoidCallback? onBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => AppSecondaryPage(
        title: title,
        onBack: onBack,
        fallbackLocation: '/records',
        actions: actions,
        child: child,
      );
}

class RecordSurface extends StatelessWidget {
  const RecordSurface({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: .12)),
        ),
        child: child,
      );
}
