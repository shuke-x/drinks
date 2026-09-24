import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../components/frosted_page_overlay.dart';
import '../../components/glass.dart';
import '../../components/app_loading_view.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/media/photo_permission.dart';
import '../../data/apis/api_providers.dart';
import '../../data/apis/upload_api.dart';
import '../../stores/settings_store.dart';
import '../../stores/user_store.dart';
import '../../l10n/l10n.dart';
import 'user_view.dart';

class ProfileDetailView extends ConsumerStatefulWidget {
  const ProfileDetailView({super.key});

  @override
  ConsumerState<ProfileDetailView> createState() => _ProfileDetailViewState();
}

class _ProfileDetailViewState extends ConsumerState<ProfileDetailView> {
  late final TextEditingController _name;
  Uint8List? _pendingAvatar;
  bool _submitting = false;

  void _endSubmitting() {
    if (mounted && _submitting) setState(() => _submitting = false);
  }

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: ref.read(userProvider).name);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    if (!await ensurePhotoPermission(context)) return;
    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 82,
        requestFullMetadata: false,
      );
      if (photo == null) return;
      final bytes = await FlutterImageCompress.compressWithList(
        await photo.readAsBytes(),
        minWidth: 512,
        minHeight: 512,
        quality: 82,
        format: CompressFormat.jpeg,
        keepExif: false,
      );
      if (!mounted) return;
      setState(() => _pendingAvatar = bytes);
    } on PlatformException catch (error) {
      if (!mounted) return;
      final denied = {'photo_access_denied', 'photo_access_restricted'}
          .contains(error.code);
      ref.read(toastProvider.notifier).show(denied
          ? context.l10n.photoAccessDenied
          : context.l10n.photoReadFailed);
    } catch (_) {
      if (!mounted) return;
      ref.read(toastProvider.notifier).show(context.l10n.photoReadFailed);
    }
  }

  Future<void> _save() async {
    if (_submitting) return;
    final name = _name.text.trim();
    if (name.isEmpty) {
      ref.read(toastProvider.notifier).show(context.l10n.nicknameCannotBeEmpty);
      return;
    }
    setState(() => _submitting = true);
    var uploadingAvatar = false;
    try {
      String? avatarUrl;
      final bytes = _pendingAvatar;
      if (bytes != null) {
        uploadingAvatar = true;
        avatarUrl = await ref.read(uploadApiProvider).uploadImage(
              MultipartFile.fromBytes(
                bytes,
                filename: 'avatar.jpg',
                contentType: DioMediaType('image', 'jpeg'),
              ),
              purpose: UploadPurpose.avatar,
            );
        uploadingAvatar = false;
      }
      await ref
          .read(userProvider.notifier)
          .updateProfile(name: name, avatarUrl: avatarUrl);
      if (!mounted) return;
      setState(() => _pendingAvatar = null);
      ref.read(toastProvider.notifier).show(context.l10n.profileSynced);
    } on ApiException catch (error) {
      if (mounted) {
        _endSubmitting();
        final message = uploadingAvatar
            ? switch (error.code) {
                400 => context.l10n.uploadInvalidImage,
                401 => context.l10n.sessionExpired,
                413 => context.l10n.uploadImageTooLarge,
                429 => context.l10n.uploadTooFrequent,
                _ => context.l10n.uploadFailed,
              }
            : error.message;
        ref.read(toastProvider.notifier).show(message);
        if (uploadingAvatar && error.code == 401) context.go('/login');
      }
    } catch (_) {
      if (mounted) {
        _endSubmitting();
        ref.read(toastProvider.notifier).show(context.l10n.saveFailed);
      }
    } finally {
      _endSubmitting();
    }
  }

  Future<void> _logout() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await ref.read(userProvider.notifier).logout();
      if (mounted) context.go('/home');
    } finally {
      _endSubmitting();
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(context.l10n.deleteAccountTitle),
        content: Text(context.l10n.deleteAccountBody),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.deletePermanently),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _submitting = true);
    try {
      await ref.read(userProvider.notifier).deleteAccount();
      if (!mounted) return;
      context.go('/home');
      ref.read(toastProvider.notifier).show(context.l10n.accountDeleted);
    } on ApiException catch (error) {
      if (mounted) {
        _endSubmitting();
        ref.read(toastProvider.notifier).show(error.message);
      }
    } catch (_) {
      if (mounted) {
        _endSubmitting();
        ref.read(toastProvider.notifier).show(context.l10n.deleteFailed);
      }
    } finally {
      _endSubmitting();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: FrostedPageOverlay(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  top + 16,
                  AppSpacing.gutter,
                  42,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlassCircleButton(
                      icon: PhosphorIcons.arrowLeft(),
                      appleSystemImageName: 'chevron.left',
                      size: 38,
                      iconSize: 17,
                      semanticLabel:
                          MaterialLocalizations.of(context).backButtonTooltip,
                      onTap: () => context.pop(),
                    ),
                    const SizedBox(height: 23),
                    Text(context.l10n.profile,
                        style: AppType.serifZh(size: 28)),
                    const SizedBox(height: 24),
                    Center(
                      child: GestureDetector(
                        onTap: user.isLoggedIn && !_submitting
                            ? _pickAvatar
                            : null,
                        child: Stack(
                          children: [
                            if (_pendingAvatar == null)
                              UserAvatar(user: user, size: 104)
                            else
                              ClipOval(
                                child: Image.memory(
                                  _pendingAvatar!,
                                  width: 104,
                                  height: 104,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            if (user.isLoggedIn)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 31,
                                  height: 31,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(
                                      color: const Color(0xFF0D0B10),
                                      width: 3,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    size: 14,
                                    color: Color(0xFF0D0B10),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    if (!user.isLoggedIn)
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.l10n.startRecordingTaste,
                                style: AppType.serifZh(size: 18)),
                            const SizedBox(height: 8),
                            Text(
                              context.l10n.loginBenefits,
                              style: AppType.sans(
                                size: 13,
                                color: Colors.white.withValues(alpha: .55),
                                height: 1.55,
                              ),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: GlassActionButton(
                                label: context.l10n.loginStart,
                                prominent: true,
                                onTap: () => context.go('/login'),
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.l10n.nickname,
                                style: AppType.eyebrow()),
                            const SizedBox(height: 9),
                            TextField(
                              controller: _name,
                              enabled: !_submitting,
                              style: AppType.sans(size: 16),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: context.l10n.enterYourName,
                                hintStyle: AppType.sans(
                                  size: 16,
                                  color: Colors.white.withValues(alpha: .32),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: GlassActionButton(
                                label: _submitting
                                    ? context.l10n.processing
                                    : context.l10n.saveProfile,
                                prominent: true,
                                onTap: _submitting ? null : _save,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: GlassActionButton(
                          label: context.l10n.logout,
                          icon: PhosphorIcons.signOut(),
                          appleSystemImageName:
                              'rectangle.portrait.and.arrow.right',
                          onTap: _submitting ? null : _logout,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: GlassActionButton(
                          label: context.l10n.deleteAccount,
                          icon: PhosphorIcons.trash(),
                          appleSystemImageName: 'trash',
                          danger: true,
                          onTap: _submitting ? null : _confirmDeleteAccount,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (_submitting)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0xB80D0B10),
                child: AppLoadingView(themeColor: AppColors.systemAccent),
              ),
            ),
        ],
      ),
    );
  }
}
