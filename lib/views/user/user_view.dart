import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../components/glass.dart';
import '../../components/palette.dart';
import '../../components/option_wheel_sheet.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../stores/settings_store.dart';
import '../../stores/user_store.dart';
import '../../l10n/l10n.dart';

/// 用户入口：资料、收藏和设置均从这里进入。
class UserView extends ConsumerStatefulWidget {
  const UserView({super.key});

  @override
  ConsumerState<UserView> createState() => _UserViewState();
}

class _UserViewState extends ConsumerState<UserView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(ambientColorProvider.notifier).state = AppColors.systemAccent;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final unit = ref.watch(appDataProvider).unit;
    final accent = ref.watch(ambientColorProvider);
    final topPad = MediaQuery.paddingOf(context).top;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.gutter, topPad + 20, AppSpacing.gutter, 132),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        RichText(
          text: TextSpan(
            style: AppType.title(
                    size: 20,
                    weight: FontWeight.w500,
                    height: 1.45,
                    color: Colors.white.withValues(alpha: .78))
                .copyWith(letterSpacing: -.12),
            children: [
              TextSpan(text: 'Perhaps ', style: TextStyle(color: accent)),
              const TextSpan(text: "we're all born "),
              TextSpan(text: '0.3%', style: TextStyle(color: accent)),
              const TextSpan(text: ' short of a good drink.'),
            ],
          ),
        ),
        const SizedBox(height: 30),
        GestureDetector(
          onTap: () =>
              context.push(user.isLoggedIn ? '/profile-detail' : '/login'),
          child: Center(
            child: Column(children: [
              UserAvatar(user: user, size: 84),
              const SizedBox(height: 11),
              Text(user.isLoggedIn ? user.name : context.l10n.tapToLogin,
                  style: AppType.serifZh(size: 19, height: 1.2)),
              const SizedBox(height: 4),
              Text(
                  user.isLoggedIn
                      ? context.l10n.editProfile
                      : context.l10n.loginManageCocktails,
                  style: AppType.sans(
                      size: 12.5, color: Colors.white.withOpacity(.48))),
            ]),
          ),
        ),
        const SizedBox(height: 28),
        _entry(
          icon: PhosphorIcons.heart(),
          title: context.l10n.myFavorites,
          subtitle: user.isLoggedIn
              ? context.l10n.favoriteCount(user.favoriteIds.length)
              : context.l10n.loginToFavoriteSubtitle,
          onTap: () => user.isLoggedIn
              ? context.push('/favorites')
              : context.push('/login'),
        ),
        const SizedBox(height: 12),
        _entry(
          icon: PhosphorIcons.sliders(),
          title: context.l10n.unitsAndCalculation,
          subtitle: unit == 'ml'
              ? context.l10n.milliliterDescription
              : context.l10n.ounceDescription,
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(unit,
                style: AppType.mono(
                    size: 12, color: Colors.white.withOpacity(.55))),
            const SizedBox(width: 4),
            Switch.adaptive(
              value: unit == 'oz',
              activeThumbColor: AppColors.systemAccent,
              onChanged: (oz) =>
                  ref.read(appDataProvider.notifier).setUnit(oz ? 'oz' : 'ml'),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        _entry(
          icon: PhosphorIcons.translate(),
          title: context.l10n.language,
          subtitle: context.l10n.languageDescription(
            _languageLabel(context, user.language),
          ),
          onTap: () => _showLanguageDialog(context, user.language),
        ),
      ]),
    );
  }

  String _languageLabel(BuildContext context, String? language) {
    if (language == 'zh') return context.l10n.languageChinese;
    if (language == 'en') return context.l10n.languageEnglish;
    return context.l10n.languageSystem;
  }

  Future<void> _showLanguageDialog(
    BuildContext context,
    String? selected,
  ) async {
    final l10n = context.l10n;
    final value = await showOptionWheel<String>(
      context: context,
      title: l10n.language,
      cancelLabel: l10n.cancel,
      doneLabel: l10n.done,
      selectedValue: selected ?? 'system',
      options: [
        OptionWheelItem(
          value: 'system',
          label: _languageLabel(context, null),
        ),
        OptionWheelItem(
          value: 'zh',
          label: _languageLabel(context, 'zh'),
        ),
        OptionWheelItem(
          value: 'en',
          label: _languageLabel(context, 'en'),
        ),
      ],
    );
    if (!mounted || value == null) return;
    try {
      await ref
          .read(userProvider.notifier)
          .setLanguage(value == 'system' ? null : value);
    } catch (_) {
      if (mounted) {
        ref.read(toastProvider.notifier).show(l10n.languageSyncFailed);
      }
    }
  }

  Widget _entry(
          {required IconData icon,
          required String title,
          required String subtitle,
          VoidCallback? onTap,
          Widget? trailing}) =>
      GestureDetector(
        onTap: onTap,
        child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              Container(
                  width: 43,
                  height: 43,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(.1)),
                  child: Icon(icon,
                      size: 20, color: Colors.white.withOpacity(.85))),
              const SizedBox(width: 13),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        style: AppType.sans(size: 15, weight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: AppType.sans(
                            size: 12, color: Colors.white.withOpacity(.47))),
                  ])),
              trailing ??
                  Icon(PhosphorIcons.caretRight(),
                      size: 17, color: Colors.white.withOpacity(.4)),
            ])),
      );
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, required this.size});
  final UserState user;
  final double size;
  @override
  Widget build(BuildContext context) {
    final bytes = _avatarBytes(user.avatarBase64);
    return Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
                colors: [Color(0xFFBF5AF2), Color(0xFF5E5CE6)]),
            border: Border.all(color: Colors.white.withOpacity(.3))),
        child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
            ? Image.network(
                user.avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(bytes),
              )
            : _fallback(bytes));
  }

  Widget _fallback(Uint8List? bytes) => bytes == null
      ? Icon(PhosphorIcons.user(),
          color: Colors.white.withValues(alpha: .9), size: size * .43)
      : Image.memory(bytes, fit: BoxFit.cover);

  /// 旧版本缓存或手工修改的本地值不应导致整个用户页崩溃。
  Uint8List? _avatarBytes(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return base64Decode(value);
    } on FormatException {
      return null;
    }
  }
}
