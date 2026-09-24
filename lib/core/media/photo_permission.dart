import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../l10n/l10n.dart';

/// Checks access only when the user starts picking, keeping app startup quiet.
Future<bool> ensurePhotoPermission(BuildContext context) async {
  if (defaultTargetPlatform != TargetPlatform.iOS) return true;

  try {
    final status = await Permission.photos.request();
    if (status.isGranted || status.isLimited) return true;
  } on MissingPluginException {
    // A hot-reloaded/old binary may not have the native permission plugin yet.
    // image_picker still owns the platform picker and can request access itself.
    return true;
  } on PlatformException {
    // Do not block the picker when the optional status check is unavailable.
    return true;
  }

  if (!context.mounted) return false;
  await showPhotoPermissionDialog(context);
  return false;
}

Future<void> showPhotoPermissionDialog(BuildContext context) async {
  final isEnglish = Localizations.localeOf(context).languageCode == 'en';
  final openSettings = await showCupertinoDialog<bool>(
    context: context,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: Text(isEnglish ? 'Photo access needed' : '需要照片权限'),
      content: Text(
        isEnglish
            ? 'Allow photo access in Settings to choose images for the app.'
            : '请在系统设置中允许照片访问，才能选择图片。',
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(context.l10n.cancel),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(isEnglish ? 'Open Settings' : '打开设置'),
        ),
      ],
    ),
  );
  if (openSettings == true) await openAppSettings();
}
