import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../components/glass.dart';
import '../../components/app_loading_view.dart';
import '../../components/palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../models/cocktail.dart';
import '../../stores/cocktail_store.dart';
import '../../stores/deck_store.dart';
import 'widgets/deck_card.dart';
import 'widgets/result_sheet.dart';

/// Next 页 —— 抽签选酒。
/// 弧形卡组物理（巡航 / 拖拽 / 抽选）由 [DeckController] 驱动，
/// 本页用 Ticker 以真实帧间隔喂给它（等价原型 requestAnimationFrame 循环）。
class NextView extends ConsumerStatefulWidget {
  const NextView({super.key});

  @override
  ConsumerState<NextView> createState() => _NextViewState();
}

class _NextViewState extends ConsumerState<NextView>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  int _lastCenter = -1;
  bool _wasTickerActive = false;

  DeckController get _deck => ref.read(deckControllerProvider);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (!mounted) return;
      final dt = (elapsed - _last).inMicroseconds / 1e6;
      _last = elapsed;
      _deck.tick(dt);
      _syncAmbient();
    })
      ..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = TickerMode.valuesOf(context).enabled;
    if (active && !_wasTickerActive) {
      // 从透明详情页、后台或非激活 Tab 回到本页时重新驱动卡组。
      _last = Duration.zero;
      _deck.resume();
    }
    _wasTickerActive = active;
  }

  void _syncAmbient() {
    final list = ref.read(allDrinksProvider);
    if (list.isEmpty) return;
    final idx = _deck.currentIndex(list.length);
    if (idx == _lastCenter) return;
    _lastCenter = idx;
    ref.read(ambientColorProvider.notifier).state = list[idx].themeColor;
  }

  /// 返回 Next 页后显式恢复卡组，避免透明覆盖路由留下暂停帧。
  Future<void> _openDetail(String id) async {
    await context.push<void>('/detail/$id');
    if (!mounted) return;
    _last = Duration.zero;
    _deck.resume();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final builtin = ref.watch(builtinDrinksProvider);
    final list = ref.watch(allDrinksProvider);
    final deck = ref.watch(deckControllerProvider);
    final ambient = ref.watch(ambientColorProvider);
    final topPad = MediaQuery.paddingOf(context).top;

    final sheetDrink = deck.sheetId == null
        ? null
        : ref.watch(drinkByIdProvider(deck.sheetId!));

    return Stack(children: [
      Column(children: [
        SizedBox(height: topPad + 14),
        // ---- 头部：Tonight / 今天喝什么 + 上传加号 ----
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter, 0, AppSpacing.gutter, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('TONIGHT',
                    style: AppType.eyebrow(
                        size: 11,
                        tracking: .18,
                        color: Colors.white.withOpacity(.42))),
                const SizedBox(height: 7),
                Text('今天喝什么', style: AppType.serifZh(size: 24, height: 1.2)),
              ]),
              GlassCircleButton(
                icon: PhosphorIcons.plus(PhosphorIconsStyle.bold),
                size: 44,
                iconSize: 18,
                iconColor: Colors.white,
                onTap: () => context.push('/upload'),
              ),
            ],
          ),
        ),
        // ---- 弧形卡组 ----
        Expanded(
          child: builtin.isLoading
              ? AppLoadingView(themeColor: ambient)
              : GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (d) =>
                      _deck.onDragStart(d.globalPosition.dx),
                  onHorizontalDragUpdate: (d) =>
                      _deck.onDragUpdate(d.globalPosition.dx),
                  onHorizontalDragEnd: (_) => _deck.onDragEnd(),
                  onHorizontalDragCancel: () => _deck.onDragEnd(),
                  child: ClipRect(
                    child: LayoutBuilder(builder: (context, box) {
                      return _DeckStack(
                        list: list,
                        deck: deck,
                        width: box.maxWidth,
                        onOpen: (id) {
                          if (deck.suppressClick || deck.spinning) return;
                          _openDetail(id);
                        },
                      );
                    }),
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 112),
          child: Text(
            '左右滑动浏览 · 点击卡片查看配方',
            style: AppType.sans(
                size: 12, color: Colors.white.withOpacity(.42), height: 1.4),
          ),
        ),
      ]),
      // ---- 抽选结果面板（原型 sheet：bottom 104）----
      if (sheetDrink != null)
        Positioned(
          left: 12,
          right: 12,
          bottom: 104,
          child: ResultSheet(
            drink: sheetDrink,
            onDetail: () {
              _deck.dismissSheet();
              _openDetail(sheetDrink.id);
            },
            onRespin: () => _deck.spin(list),
          ),
        ),
    ]);
  }
}

/// 弧形卡组渲染：可见槽位 -3..+3，远卡先画（等价原型 z-index）。
class _DeckStack extends StatelessWidget {
  const _DeckStack({
    required this.list,
    required this.deck,
    required this.width,
    required this.onOpen,
  });

  final List<Cocktail> list;
  final DeckController deck;
  final double width;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) return const SizedBox.expand();

    final len = list.length;
    final base = deck.pos.round();
    final slots = <_Slot>[];
    for (var k = -3; k <= 3; k++) {
      final slot = base + k;
      final d = list[((slot % len) + len) % len];
      final t = slot - deck.pos;
      slots.add(_Slot(drink: d, t: t, key: 's$k'));
    }
    // 按距离降序绘制：近的卡后画（在最上层）
    slots.sort((a, b) => b.t.abs().compareTo(a.t.abs()));

    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final s in slots)
          DeckCardTransform(
            key: ValueKey(s.key),
            drink: s.drink,
            t: s.t,
            stageWidth: width,
            landed: deck.landedId == s.drink.id && s.t.abs() < 0.4,
            onTap: () => onOpen(s.drink.id),
          ),
      ],
    );
  }
}

class _Slot {
  final Cocktail drink;
  final double t;
  final String key;
  const _Slot({required this.drink, required this.t, required this.key});
}
