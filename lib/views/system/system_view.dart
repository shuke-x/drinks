import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../components/glass.dart';
import '../../components/cocktail_cover.dart';
import '../../components/palette.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_effects.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../stores/settings_store.dart';

class SystemView extends ConsumerStatefulWidget {
  const SystemView({super.key});

  @override
  ConsumerState<SystemView> createState() => _SystemViewState();
}

class _SystemViewState extends ConsumerState<SystemView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 原型 themeColor()：System 页固定 #5E5CE6
      ref.read(ambientColorProvider.notifier).state = AppColors.systemAccent;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appDataProvider);
    final topPad = MediaQuery.paddingOf(context).top;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.gutter, topPad + 20, AppSpacing.gutter, 132),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('系统', style: AppType.serifZh(size: 28, height: 1.15)),
        const SizedBox(height: 4),
        Text('在 Next 页右上角的加号里上传新酒单。',
            style: AppType.sans(
                size: 13, color: Colors.white.withOpacity(.5), height: 1.5)),
        const SizedBox(height: 20),

        // ---- 我的酒单 ----
        GlassCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('我的酒单 · ${data.mine.length}', style: AppType.eyebrow()),
            const SizedBox(height: 14),
            if (data.mine.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 2),
                child: Text('还没有上传配方。加一杯属于你的招牌。',
                    style: AppType.sans(
                        size: 13,
                        color: Colors.white.withOpacity(.4),
                        height: 1.6)),
              ),
            Column(children: [
              for (final m in data.mine)
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.white.withOpacity(.06),
                      border: Border.all(color: AppColors.glassBorder12),
                    ),
                    child: Row(children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CocktailCover(drink: m),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.zh,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    AppType.serifZh(size: 14.5, height: 1.2)),
                            const SizedBox(height: 3),
                            Text('${m.base} · ${m.recipe.length} 种原料',
                                style: AppType.sans(
                                    size: 11.5,
                                    color: Colors.white.withOpacity(.45),
                                    height: 1.3)),
                          ],
                        ),
                      ),
                      GlassCircleButton(
                        icon: PhosphorIcons.pencilSimple(),
                        size: 32,
                        iconSize: 14,
                        onTap: () => context.push('/upload?edit=${m.id}'),
                      ),
                      const SizedBox(width: 8),
                      GlassCircleButton(
                        icon: PhosphorIcons.trash(),
                        size: 32,
                        iconSize: 14,
                        onTap: () {
                          ref.read(appDataProvider.notifier).remove(m.id);
                          ref.read(toastProvider.notifier).show('已删除');
                        },
                      ),
                    ]),
                  ),
                ),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        // ---- 设置 ----
        GlassCard(
          padding: EdgeInsets.zero,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
              child: Text('设置', style: AppType.eyebrow()),
            ),
            _row(
              label: '计量单位',
              trailing: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: const Color(0xFF787880).withOpacity(.32),
                  border: Border.all(color: Colors.white.withOpacity(.1)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _unitSeg('ml', data.unit == 'ml'),
                  _unitSeg('oz', data.unit == 'oz'),
                ]),
              ),
            ),
            _row(
              label: '导出数据',
              trailing: Icon(PhosphorIcons.export(),
                  size: 17, color: Colors.white.withOpacity(.5)),
              onTap: () async {
                final json = ref.read(appDataProvider.notifier).exportJson();
                await Clipboard.setData(ClipboardData(text: json));
                if (!context.mounted) return;
                ref.read(toastProvider.notifier).show('已导出 JSON 到剪贴板');
              },
            ),
            _row(
              label: '清空我的酒单',
              labelColor: AppColors.danger,
              trailing: Icon(PhosphorIcons.trashSimple(),
                  size: 17, color: AppColors.danger.withOpacity(.75)),
              onTap: () {
                ref.read(appDataProvider.notifier).clear();
                ref.read(toastProvider.notifier).show('已清空我的酒单');
              },
            ),
            _row(
              label: '关于',
              trailing: Text('今晚喝什么 1.0',
                  style: AppType.mono(
                      size: 12.5, color: Colors.white.withOpacity(.45))),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _unitSeg(String unit, bool active) {
    return GestureDetector(
      onTap: () => ref.read(appDataProvider.notifier).setUnit(unit),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: AppMotion.spring,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          color: active ? Colors.white.withOpacity(.94) : Colors.transparent,
        ),
        child: Text(unit,
            style: AppType.mono(
                size: 12,
                color: active
                    ? const Color(0xFF0D0B10)
                    : Colors.white.withOpacity(.6))),
      ),
    );
  }

  Widget _row({
    required String label,
    required Widget trailing,
    Color? labelColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.hairline)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppType.sans(
                    size: 14.5,
                    weight: FontWeight.w500,
                    color: labelColor ?? Colors.white,
                    height: 1.0)),
            trailing,
          ],
        ),
      ),
    );
  }
}
