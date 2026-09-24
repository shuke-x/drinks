import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/generated/app_localizations.dart';
import 'user_store.dart';

String resolveAppLanguage(String? preference, [List<Locale>? locales]) =>
    basicLocaleListResolution(
      preference == null
          ? locales ?? WidgetsBinding.instance.platformDispatcher.locales
          : [Locale(preference)],
      AppLocalizations.supportedLocales,
    ).languageCode;

class _LocaleObserver extends WidgetsBindingObserver {
  _LocaleObserver(this.onChanged);
  final VoidCallback onChanged;

  @override
  void didChangeLocales(List<Locale>? locales) => onChanged();
}

final _systemLocalesProvider = Provider<List<Locale>>((ref) {
  final observer = _LocaleObserver(ref.invalidateSelf);
  WidgetsBinding.instance.addObserver(observer);
  ref.onDispose(() => WidgetsBinding.instance.removeObserver(observer));
  return WidgetsBinding.instance.platformDispatcher.locales;
});

final Provider<String> appLanguageProvider = Provider<String>((ref) {
  final preference = ref.watch(userProvider.select((user) => user.language));
  return resolveAppLanguage(preference, ref.watch(_systemLocalesProvider));
});
