import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../components/app_loading_view.dart';
import '../../components/common_text.dart';
import '../../components/glass.dart';
import '../../core/auth/token_storage.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_effects.dart';
import '../../core/theme/app_typography.dart';
import '../../data/apis/api_providers.dart';
import '../../stores/settings_store.dart';
import '../../stores/user_store.dart';
import '../../l10n/l10n.dart';

/// 登录 / 注册页：一张留在吧台上的暖色小卡，而不是高对比的系统弹层。
class AuthGateView extends ConsumerStatefulWidget {
  const AuthGateView({super.key});

  @override
  ConsumerState<AuthGateView> createState() => _AuthGateViewState();
}

class _AuthGateViewState extends ConsumerState<AuthGateView> {
  bool _register = false;
  bool _submitting = false;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pw = TextEditingController();

  void _endSubmitting() {
    if (mounted && _submitting) setState(() => _submitting = false);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) {
      debugPrint('[AuthGate] submit ignored: request already in progress');
      return;
    }
    final toast = ref.read(toastProvider.notifier);
    final l10n = context.l10n;
    final email = _email.text.trim();
    final mode = _register ? 'register' : 'login';
    debugPrint('[AuthGate] $mode tapped; emailEntered=${email.isNotEmpty}; '
        'passwordLength=${_pw.text.length}; nameEntered=${_name.text.trim().isNotEmpty}');
    if (!RegExp(r'.+@.+\..+').hasMatch(email)) {
      debugPrint('[AuthGate] $mode blocked: invalid email');
      toast.show(l10n.validEmailRequired);
      return;
    }
    if (_pw.text.length < 6) {
      debugPrint('[AuthGate] $mode blocked: password shorter than 6');
      toast.show(l10n.passwordSixCharacters);
      return;
    }
    if (_register && _name.text.trim().isEmpty) {
      debugPrint('[AuthGate] register blocked: missing nickname');
      toast.show(l10n.nicknameRequired);
      return;
    }
    if (_register &&
        !RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^\w\s]).{8,}$')
            .hasMatch(_pw.text)) {
      debugPrint('[AuthGate] register blocked: password policy not satisfied');
      toast.show(l10n.passwordPolicy);
      return;
    }
    final name = _register ? _name.text.trim() : email.split('@').first;
    setState(() => _submitting = true);
    try {
      debugPrint('[AuthGate] requesting $mode API');
      final auth = ref.read(authApiProvider);
      final tokens = _register
          ? await auth.register(email: email, password: _pw.text, name: name)
          : await auth.login(email: email, password: _pw.text);
      debugPrint('[AuthGate] $mode API succeeded; saving session');
      await TokenStorage.instance.save(tokens);
      await ref
          .read(userProvider.notifier)
          .establishSession(fallbackName: name);
      _name.clear();
      _email.clear();
      _pw.clear();
      toast.show(_register ? l10n.registerWelcome : l10n.welcomeBack(name));
      if (mounted) {
        final destination = _register ? '/home' : '/profile';
        debugPrint('[AuthGate] session saved; navigating to $destination');
        context.go(destination);
      }
    } on ApiException catch (error) {
      debugPrint('[AuthGate] $mode API error: ${error.message}');
      _endSubmitting();
      toast.show(error.message);
    } catch (error, stackTrace) {
      debugPrint('[AuthGate] $mode unexpected error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _endSubmitting();
      toast.show(l10n.authFailed);
    } finally {
      _endSubmitting();
      debugPrint('[AuthGate] $mode request finished');
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F10),
      resizeToAvoidBottomInset: true,
      body: Stack(fit: StackFit.expand, children: [
        const _GateBackground(),
        SafeArea(
          bottom: false,
          child: LayoutBuilder(builder: (context, box) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, topPad + 22, 24, 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      RiseIn(
                        duration: const Duration(milliseconds: 680),
                        child: _BrandHeader(),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 42),
                        child: RiseIn(
                          duration: const Duration(milliseconds: 720),
                          delay: const Duration(milliseconds: 110),
                          child: _AuthCard(
                            register: _register,
                            name: _name,
                            email: _email,
                            password: _pw,
                            onModeChanged: (value) {
                              debugPrint('[AuthGate] mode changed to '
                                  '${value ? 'register' : 'login'}');
                              setState(() => _register = value);
                            },
                            onSubmit: _submit,
                            onGuest: () => context.go('/home'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
        if (_submitting)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0xB80F0F10),
              child: AppLoadingView(themeColor: Color(0xFF0A84FF)),
            ),
          ),
      ]),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFF242426),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x26FFFFFF)),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 28,
                    offset: Offset(0, 14)),
              ],
            ),
            child: Icon(PhosphorIcons.martini(PhosphorIconsStyle.light),
                size: 28, color: const Color(0xFFEBEBF5)),
          ),
          const SizedBox(height: 30),
          AppTitle(context.l10n.authHero, level: AppTitleLevel.hero),
          const SizedBox(height: 10),
          AppTips(context.l10n.authSubtitle, color: const Color(0x94EBEBF5)),
        ],
      );
}

class _AuthCard extends StatelessWidget {
  const _AuthCard(
      {required this.register,
      required this.name,
      required this.email,
      required this.password,
      required this.onModeChanged,
      required this.onSubmit,
      required this.onGuest});
  final bool register;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController password;
  final ValueChanged<bool> onModeChanged;
  final VoidCallback onSubmit;
  final VoidCallback onGuest;

  @override
  Widget build(BuildContext context) => AutofillGroup(
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0x2EFFFFFF)),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 19, 18, 17),
            decoration: BoxDecoration(
              color: const Color(0xE01C1C1E),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: const Color(0x16FFFFFF)),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x1F050303),
                    blurRadius: 38,
                    offset: Offset(0, 18))
              ],
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AuthSegmented(register: register, onChanged: onModeChanged),
                  const SizedBox(height: 22),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 420),
                    curve: const Cubic(.22, .8, .2, 1),
                    child: register
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _GateField(
                              controller: name,
                              hint: context.l10n.nickname,
                              icon: PhosphorIcons.user(),
                              autofillHints: const [AutofillHints.name],
                              textCapitalization: TextCapitalization.words,
                            ))
                        : const SizedBox.shrink(),
                  ),
                  _GateField(
                      controller: email,
                      hint: context.l10n.emailAddress,
                      icon: PhosphorIcons.envelopeSimple(),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [
                        AutofillHints.username,
                        AutofillHints.email,
                      ],
                      autocorrect: false,
                      enableSuggestions: false),
                  const SizedBox(height: 12),
                  _GateField(
                      controller: password,
                      hint: context.l10n.password,
                      icon: PhosphorIcons.lockKey(),
                      obscure: true,
                      autofillHints: [
                        register
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      autocorrect: false,
                      enableSuggestions: false,
                      onSubmitted: (_) => onSubmit()),
                  if (register) ...[
                    const SizedBox(height: 10),
                    Text(context.l10n.passwordPolicy,
                        style: AppType.sans(
                            size: 11.5,
                            color: const Color(0xFFEBEBF5)
                                .withValues(alpha: .45))),
                  ],
                  const SizedBox(height: 22),
                  PressScale(
                    onTap: onSubmit,
                    child: Container(
                      height: 58,
                      padding: const EdgeInsets.only(left: 22, right: 7),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFC9B2DB),
                                Color(0xFFD7AEC0),
                                Color(0xFFD9BE9D)
                              ]),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x1FBA95B8),
                                blurRadius: 22,
                                offset: Offset(0, 10))
                          ]),
                      child: Row(children: [
                        Expanded(
                            child: Text(
                                register
                                    ? context.l10n.startCreating
                                    : context.l10n.continueTonight,
                                style: AppType.sans(
                                    size: 16,
                                    weight: FontWeight.w600,
                                    color: const Color(0xFF30242E),
                                    letterSpacing: -.2))),
                        SizedBox(
                            width: 30,
                            height: 30,
                            child: Icon(PhosphorIcons.arrowRight(),
                                size: 19, color: const Color(0xFF30242E))),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 19),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(context.l10n.notLoginNow,
                        style: AppType.sans(
                            size: 13.5,
                            color: const Color(0xFFEBEBF5)
                                .withValues(alpha: .46))),
                    const SizedBox(width: 6),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onGuest,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Text(context.l10n.browseAsGuest,
                            style: AppType.sans(
                                size: 13.5,
                                weight: FontWeight.w700,
                                color: const Color(0xFFF2EAF4))),
                      ),
                    ),
                  ]),
                ]),
          ),
        ),
      );
}

class _GateBackground extends StatelessWidget {
  const _GateBackground();
  @override
  Widget build(BuildContext context) =>
      const Stack(fit: StackFit.expand, children: [
        ColoredBox(color: Color(0xFF0F0F10)),
        _SoftOrb(
            alignment: Alignment(-1.12, -.82),
            size: 250,
            color: Color(0x1FFFFFFF)),
        _SoftOrb(
            alignment: Alignment(.96, .48),
            size: 290,
            color: Color(0x14FFFFFF)),
        DecoratedBox(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x000F0F10), Color(0x73000000)]))),
      ]);
}

class _SoftOrb extends StatelessWidget {
  const _SoftOrb(
      {required this.alignment, required this.size, required this.color});
  final Alignment alignment;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Align(
        alignment: alignment,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 46, sigmaY: 46),
          child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        ),
      );
}

class _AuthSegmented extends StatelessWidget {
  const _AuthSegmented({required this.register, required this.onChanged});
  final bool register;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x1FFFFFFF))),
        child: Stack(children: [
          AnimatedAlign(
              alignment:
                  register ? Alignment.centerRight : Alignment.centerLeft,
              duration: const Duration(milliseconds: 380),
              curve: const Cubic(.22, .8, .2, 1),
              child: FractionallySizedBox(
                  widthFactor: .5,
                  heightFactor: 1,
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                          color: const Color(0x33FFFFFF),
                          border: Border.all(color: const Color(0x3DFFFFFF)),
                          borderRadius: BorderRadius.circular(11))))),
          Row(children: [
            _item(context.l10n.login, !register, () => onChanged(false)),
            _item(context.l10n.register, register, () => onChanged(true)),
          ]),
        ]),
      );
  Widget _item(String label, bool active, VoidCallback onTap) => Expanded(
      child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Center(
              child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 280),
                  curve: AppMotion.standard,
                  style: AppType.sans(
                      size: 13.5,
                      weight: FontWeight.w600,
                      color: active ? Colors.white : const Color(0xFF98989D)),
                  child: Text(label)))));
}

class _GateField extends StatefulWidget {
  const _GateField(
      {required this.controller,
      required this.hint,
      required this.icon,
      this.obscure = false,
      this.keyboardType,
      this.autofillHints,
      this.textCapitalization = TextCapitalization.none,
      this.autocorrect = true,
      this.enableSuggestions = true,
      this.onSubmitted});
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final bool enableSuggestions;
  final ValueChanged<String>? onSubmitted;
  @override
  State<_GateField> createState() => _GateFieldState();
}

class _GateFieldState extends State<_GateField> {
  final _focus = FocusNode();
  late bool _obscureText;
  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscure;
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: const Cubic(.22, .8, .2, 1),
        height: 52,
        decoration: BoxDecoration(
            color: _focus.hasFocus
                ? const Color(0xFF2C2C2E)
                : const Color(0xFF242426),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: _focus.hasFocus
                    ? const Color(0x99FFFFFF)
                    : const Color(0x1FFFFFFF))),
        child: TextField(
          controller: widget.controller,
          focusNode: _focus,
          obscureText: _obscureText,
          keyboardType: widget.keyboardType,
          autofillHints: widget.autofillHints,
          textCapitalization: widget.textCapitalization,
          autocorrect: widget.autocorrect,
          enableSuggestions: widget.enableSuggestions,
          textAlignVertical: TextAlignVertical.center,
          onSubmitted: widget.onSubmitted,
          textInputAction: widget.onSubmitted == null
              ? TextInputAction.next
              : TextInputAction.done,
          style: AppType.sans(size: 15.5, color: const Color(0xFFF2F2F7)),
          cursorColor: const Color(0xFFF2F2F7),
          decoration: InputDecoration(
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 52, minHeight: 52),
              prefixIcon: Icon(widget.icon,
                  size: 19,
                  color: _focus.hasFocus
                      ? const Color(0xFFF2F2F7)
                      : const Color(0xFF98989D)),
              suffixIcon: widget.obscure
                  ? IconButton(
                      tooltip: _obscureText
                          ? context.l10n.showPassword
                          : context.l10n.hidePassword,
                      onPressed: () =>
                          setState(() => _obscureText = !_obscureText),
                      icon: Icon(
                        _obscureText
                            ? PhosphorIcons.eye()
                            : PhosphorIcons.eyeSlash(),
                        size: 19,
                        color: const Color(0xFF98989D),
                      ),
                    )
                  : null,
              hintText: widget.hint,
              hintStyle: AppType.sans(size: 15, color: const Color(0xFF98989D)),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.only(right: 16)),
        ),
      );
}
