import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../components/glass.dart';
import '../../components/cocktail_cover.dart';
import '../../components/app_loading_view.dart';
import '../../components/frosted_page_overlay.dart';
import '../../components/palette.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../stores/cocktail_store.dart';
import '../../stores/deck_store.dart';
import '../../stores/settings_store.dart';

/// 详情覆盖层 —— 原型 detail：
/// 全屏 rgba(13,11,16,.72)+blur(26) 覆盖，330 高渐变头图 + 光球 + 玻璃环，
/// 内容卡片以 riseIn 交错入场（延迟每层 +0.08s）。
class DetailView extends ConsumerStatefulWidget {
  const DetailView({super.key, required this.id});

  final String id;

  @override
  ConsumerState<DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends ConsumerState<DetailView> {
  Color? _prevAmbient;
  late final StateController<Color> _ambientController;
  late final DeckController _deckController;

  @override
  void initState() {
    super.initState();
    _ambientController = ref.read(ambientColorProvider.notifier);
    _deckController = ref.read(deckControllerProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final drink = ref.read(drinkByIdProvider(widget.id));
      if (drink != null) {
        _prevAmbient = ref.read(ambientColorProvider);
        _ambientController.state = drink.themeColor;
      }
      // 原型：详情打开时卡组巡航暂停
      _deckController.pause();
    });
  }

  @override
  void dispose() {
    // 恢复氛围色与巡航
    if (_prevAmbient != null) {
      _ambientController.state = _prevAmbient!;
    }
    _deckController.resume();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drink = ref.watch(drinkByIdProvider(widget.id));
    final unit = ref.watch(appDataProvider).unit;
    final topPad = MediaQuery.paddingOf(context).top;
    final ambient = ref.watch(ambientColorProvider);

    if (drink == null) {
      return Scaffold(
        backgroundColor: const Color(0xB80D0B10),
        body: AppLoadingView(themeColor: ambient),
      );
    }

    final c = drink.themeColor;
    final chips = <String>[drink.base, '${drink.abv}% ABV', ...drink.tags];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FrostedPageOverlay(
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // ---- 头图 ----
            SizedBox(
              height: 330,
              child: Stack(children: [
                Positioned.fill(
                  child: CocktailCover(drink: drink),
                ),
                // 大光球
                if (drink.images.isEmpty)
                  Align(
                    alignment: const Alignment(0, .1),
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: drinkOrb(c),
                      ),
                    ),
                  ),
                // 玻璃圆环与默认圆球成组展示；有封面图片时不叠加。
                if (drink.images.isEmpty)
                  Align(
                    alignment: const Alignment(0, .1),
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(.3)),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(.24),
                            Colors.white.withOpacity(.05),
                          ],
                        ),
                      ),
                    ),
                  ),
                // 底部渐隐到基底
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 120,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          const Color(0xFF0D0B10).withOpacity(.9),
                          const Color(0xFF0D0B10).withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),
                // 返回按钮
                Positioned(
                  left: 16,
                  top: topPad + 8,
                  child: GlassCircleButton(
                    icon: PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
                    size: 38,
                    iconSize: 16,
                    iconColor: Colors.white,
                    onTap: () => context.pop(),
                  ),
                ),
              ]),
            ),

            // ---- 内容（上移 52 叠在头图渐隐区上）----
            Transform.translate(
              offset: const Offset(0, -52),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter, 0, AppSpacing.gutter, 0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RiseIn(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(drink.en, style: AppType.playfair(size: 15)),
                              const SizedBox(height: 7),
                              Text(drink.zh,
                                  style:
                                      AppType.serifZh(size: 32, height: 1.15)),
                              const SizedBox(height: 13),
                              Wrap(spacing: 7, runSpacing: 7, children: [
                                for (final t in chips)
                                  InfoPill(
                                    label: t,
                                    fontSize: 11,
                                    fill: Colors.white.withOpacity(.1),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 7),
                                  ),
                              ]),
                            ]),
                      ),
                      const SizedBox(height: 18),

                      // 配方
                      RiseIn(
                        delay: const Duration(milliseconds: 80),
                        child: GlassCard(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('配方 · ${unit == 'oz' ? '盎司' : '毫升'}',
                                    style: AppType.eyebrow()),
                                const SizedBox(height: 5),
                                for (final r in drink.recipe)
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 9),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                            color:
                                                Colors.white.withOpacity(.07)),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(r.n,
                                            style: AppType.sans(
                                                size: 14.5,
                                                weight: FontWeight.w500,
                                                height: 1.3)),
                                        Text(formatAmount(r, unit),
                                            style: AppType.mono(
                                                size: 13,
                                                weight: FontWeight.w400,
                                                color: Colors.white
                                                    .withOpacity(.62))),
                                      ],
                                    ),
                                  ),
                              ]),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 调制步骤
                      RiseIn(
                        delay: const Duration(milliseconds: 160),
                        child: GlassCard(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('调制步骤', style: AppType.eyebrow()),
                                const SizedBox(height: 14),
                                for (var i = 0; i < drink.steps.length; i++)
                                  Padding(
                                    padding: EdgeInsets.only(
                                        bottom: i == drink.steps.length - 1
                                            ? 0
                                            : 13),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 23,
                                          height: 23,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color:
                                                Colors.white.withOpacity(.92),
                                          ),
                                          child: Text('${i + 1}',
                                              style: AppType.mono(
                                                  size: 11,
                                                  color:
                                                      const Color(0xFF0D0B10))),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(drink.steps[i],
                                              style: AppType.sans(
                                                  size: 14,
                                                  color: Colors.white
                                                      .withOpacity(.86),
                                                  height: 1.55)),
                                        ),
                                      ],
                                    ),
                                  ),
                              ]),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 杯具 / 装饰
                      Row(children: [
                        Expanded(
                          child: RiseIn(
                            delay: const Duration(milliseconds: 240),
                            child: _miniCard(
                                PhosphorIcons.martini(), '杯具', drink.glass),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RiseIn(
                            delay: const Duration(milliseconds: 300),
                            child: _miniCard(
                                PhosphorIcons.leaf(), '装饰', drink.garnish),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 14),

                      // 风味故事
                      RiseIn(
                        delay: const Duration(milliseconds: 380),
                        child: GlassCard(
                          fillOpacity: .07,
                          borderOpacity: .14,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('风味故事', style: AppType.eyebrow()),
                                const SizedBox(height: 12),
                                Text(drink.story,
                                    style: AppType.playfair(
                                        size: 17,
                                        color: Colors.white.withOpacity(.9),
                                        height: 1.6)),
                              ]),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _miniCard(IconData icon, String label, String value) {
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(16),
      shadow: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 19, color: Colors.white.withOpacity(.55)),
        const SizedBox(height: 11),
        Text(label.toUpperCase(),
            style: AppType.eyebrow(
                size: 11, tracking: .12, color: AppColors.text42)),
        const SizedBox(height: 6),
        Text(value,
            style: AppType.serifZh(
                size: 15, weight: FontWeight.w500, height: 1.3)),
      ]),
    );
  }
}
