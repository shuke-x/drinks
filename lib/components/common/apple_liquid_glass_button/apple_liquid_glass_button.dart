import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A narrow bridge to UIKit's native Liquid Glass button configuration.
///
/// This widget is only built on iOS. Callers must provide their existing
/// Flutter implementation as the fallback for other platforms.
class AppleLiquidGlassButton extends StatefulWidget {
  /// 创建一个由 UIKit 承载的系统 Liquid Glass 按钮。
  ///
  /// [key] 用于在 Widget 树中标识这个原生平台视图。
  const AppleLiquidGlassButton({
    super.key,
    required this.onPressed,
    this.label,
    this.systemImageName,
    this.semanticLabel,
    this.foregroundColor = Colors.white,
    this.backgroundColor,
    this.prominent = false,
    this.fontSize = 13.5,
    this.imagePadding = 8,
    this.imageTrailing = false,
    this.spreadContent = false,
  })  : assert(label != null || systemImageName != null),
        assert(fontSize > 0);

  /// 点击回调。为 `null` 时 UIKit 按钮处于禁用状态。
  final VoidCallback? onPressed;

  /// 可选按钮文案；与 [systemImageName] 至少提供一个。
  final String? label;

  /// 可选 SF Symbol 名称，例如 `arrow.right`。
  final String? systemImageName;

  /// VoiceOver 读取的标签；省略时回退到 [label]。
  final String? semanticLabel;

  /// 文案与 SF Symbol 的前景色，默认白色。
  final Color foregroundColor;

  /// Optional Liquid Glass surface tint.
  final Color? backgroundColor;

  /// 是否使用系统 `prominentGlass`；否则使用普通 `glass`。
  final bool prominent;

  /// Button title font size in logical points.
  final double fontSize;

  /// 文案与图标之间的间距，单位为 pt，默认 8。
  final double imagePadding;

  /// 是否把图标放在文案之后，默认放在之前。
  final bool imageTrailing;

  /// 是否让文案和图标分别贴近按钮两端。
  ///
  /// 仅适用于有明确宽度的横向选择按钮，不应用于 44pt 圆形按钮。
  final bool spreadContent;

  static bool get isApplePlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  State<AppleLiquidGlassButton> createState() => _AppleLiquidGlassButtonState();
}

class _AppleLiquidGlassButtonState extends State<AppleLiquidGlassButton> {
  MethodChannel? _channel;

  Map<String, Object?> get _configuration => <String, Object?>{
        'label': widget.label,
        'systemImageName': widget.systemImageName,
        'semanticLabel': widget.semanticLabel ?? widget.label,
        'foregroundColor': widget.foregroundColor.toARGB32(),
        if (widget.backgroundColor != null)
          'backgroundColor': widget.backgroundColor!.toARGB32(),
        'prominent': widget.prominent,
        'fontSize': widget.fontSize,
        'enabled': widget.onPressed != null,
        'imagePadding': widget.imagePadding,
        'imageTrailing': widget.imageTrailing,
        'spreadContent': widget.spreadContent,
      };

  @override
  void didUpdateWidget(covariant AppleLiquidGlassButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.label != widget.label ||
        oldWidget.systemImageName != widget.systemImageName ||
        oldWidget.semanticLabel != widget.semanticLabel ||
        oldWidget.foregroundColor != widget.foregroundColor ||
        oldWidget.backgroundColor != widget.backgroundColor ||
        oldWidget.prominent != widget.prominent ||
        oldWidget.fontSize != widget.fontSize ||
        oldWidget.onPressed != widget.onPressed ||
        oldWidget.imagePadding != widget.imagePadding ||
        oldWidget.imageTrailing != widget.imageTrailing ||
        oldWidget.spreadContent != widget.spreadContent) {
      _channel?.invokeMethod<void>('update', _configuration);
    }
  }

  void _onPlatformViewCreated(int viewId) {
    final channel = MethodChannel(
      'tonight_drinks/apple_liquid_glass_button/$viewId',
    );
    channel.setMethodCallHandler((call) async {
      if (call.method != 'tap' || !mounted) return;
      final onPressed = widget.onPressed;
      if (onPressed == null) return;

      // Let the platform-view method call finish before navigation can hide
      // or dispose the native button. This is especially important for the
      // retained bottom controls, which are made Offstage as soon as a
      // secondary route starts its Cupertino transition.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) onPressed();
      });
      WidgetsBinding.instance.scheduleFrame();
    });
    _channel = channel;
    channel.invokeMethod<void>('update', _configuration);
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(AppleLiquidGlassButton.isApplePlatform);
    return UiKitView(
      viewType: 'tonight_drinks/apple_liquid_glass_button',
      creationParams: _configuration,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onPlatformViewCreated,
    );
  }
}

/// Resolves native Liquid Glass availability once for the running process.
/// iOS versions before 26 deliberately stay on the Flutter fallback.
class AppleLiquidGlassSwitcher extends StatelessWidget {
  /// 创建一个按系统能力选择原生 Liquid Glass 或 Flutter fallback 的容器。
  ///
  /// [key] 用于在 Widget 树中标识这个自适应边界。
  const AppleLiquidGlassSwitcher({
    super.key,
    required this.nativeBuilder,
    required this.fallback,
  });

  /// iOS 26+ 支持系统 Liquid Glass 时构建原生控件。
  final WidgetBuilder nativeBuilder;

  /// 低版本 iOS 及其他平台使用的 Flutter 实现。
  final Widget fallback;

  static const _capabilities = MethodChannel(
    'tonight_drinks/apple_ui_capabilities',
  );
  static Future<bool>? _cachedAvailability;
  static bool? _resolvedAvailability;

  static Future<bool> _resolveAvailability() async {
    if (!AppleLiquidGlassButton.isApplePlatform) {
      _resolvedAvailability = false;
      return false;
    }
    var supported = false;
    try {
      supported =
          await _capabilities.invokeMethod<bool>('supportsLiquidGlass') ??
              false;
    } on PlatformException {
      supported = false;
    } on MissingPluginException {
      supported = false;
    }
    _resolvedAvailability = supported;
    return supported;
  }

  @override
  Widget build(BuildContext context) {
    if (!AppleLiquidGlassButton.isApplePlatform) return fallback;
    final resolved = _resolvedAvailability;
    if (resolved != null) {
      return resolved ? nativeBuilder(context) : fallback;
    }
    _cachedAvailability ??= _resolveAvailability();
    return FutureBuilder<bool>(
      future: _cachedAvailability,
      initialData: false,
      builder: (context, snapshot) =>
          snapshot.data == true ? nativeBuilder(context) : fallback,
    );
  }
}
