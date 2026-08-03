import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppleLiquidGlassTabItem {
  /// 创建一个传递给 UIKit TabBar 的目标项。
  const AppleLiquidGlassTabItem({
    required this.label,
    required this.systemImageName,
    required this.selectedSystemImageName,
  });

  /// Tab 的可见文案及 VoiceOver 名称。
  final String label;

  /// 未选中状态使用的 SF Symbol 名称。
  final String systemImageName;

  /// 选中状态使用的 SF Symbol 名称。
  final String selectedSystemImageName;

  Map<String, Object> toMap() => <String, Object>{
        'label': label,
        'systemImageName': systemImageName,
        'selectedSystemImageName': selectedSystemImageName,
      };
}

class AppleLiquidGlassTabBar extends StatefulWidget {
  /// 创建一个 UIKit 承载的系统 Liquid Glass TabBar。
  ///
  /// [key] 用于在 Widget 树中标识这个原生平台视图。
  const AppleLiquidGlassTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
  });

  /// Tab 目标列表；顺序必须与根路由顺序一致。
  final List<AppleLiquidGlassTabItem> items;

  /// 当前选中项的零起始下标。
  final int currentIndex;

  /// 用户选择新 Tab 时返回其零起始下标。
  final ValueChanged<int> onSelected;

  @override
  State<AppleLiquidGlassTabBar> createState() => _AppleLiquidGlassTabBarState();
}

class _AppleLiquidGlassTabBarState extends State<AppleLiquidGlassTabBar> {
  MethodChannel? _channel;

  Map<String, Object> get _configuration => <String, Object>{
        'currentIndex': widget.currentIndex,
        'items': widget.items.map((item) => item.toMap()).toList(),
      };

  @override
  void didUpdateWidget(covariant AppleLiquidGlassTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex ||
        oldWidget.items != widget.items) {
      _channel?.invokeMethod<void>('update', _configuration);
    }
  }

  void _onPlatformViewCreated(int viewId) {
    final channel = MethodChannel(
      'tonight_drinks/apple_liquid_glass_tab_bar/$viewId',
    );
    channel.setMethodCallHandler((call) async {
      if (call.method == 'select' && mounted) {
        final index = call.arguments as int?;
        if (index != null) widget.onSelected(index);
      }
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
  Widget build(BuildContext context) => UiKitView(
        viewType: 'tonight_drinks/apple_liquid_glass_tab_bar',
        creationParams: _configuration,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      );
}
