import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../components/glass.dart';
import '../../components/app_loading_view.dart';
import '../../components/app_empty_view.dart';
import '../../components/palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/interaction/app_feedback.dart';
import '../../models/cocktail.dart';
import '../../stores/cocktail_store.dart';
import '../../stores/deck_store.dart';
import '../../stores/user_store.dart';
import '../../stores/settings_store.dart';
import '../../l10n/l10n.dart';
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
  bool _reduceMotion = false;
  String? _lastSheetId;

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
      _syncResultFeedback();
    })
      ..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = TickerMode.valuesOf(context).enabled;
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _ticker.muted = !active || _reduceMotion;
    if (active && !_wasTickerActive) {
      // 从透明详情页、后台或非激活 Tab 回到本页时重新驱动卡组。
      _last = Duration.zero;
      // didChangeDependencies 发生在 build 锁内；resume 会 notifyListeners，
      // 必须等这一帧完成，避免 Riverpod 的「build 期间修改 Provider」异常。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !TickerMode.valuesOf(context).enabled) return;
        if (_reduceMotion) {
          _deck.pause();
        } else {
          _deck.resume();
        }
      });
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

  void _syncResultFeedback() {
    final sheetId = _deck.sheetId;
    if (sheetId == null || sheetId == _lastSheetId) return;
    _lastSheetId = sheetId;
    AppFeedback.success();
  }

  /// 返回 Next 页后显式恢复卡组，避免透明覆盖路由留下暂停帧。
  Future<void> _openDetail(Cocktail drink) async {
    await context.push<void>('/detail/${drink.id}', extra: drink);
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
    final deck = ref.read(deckControllerProvider);
    final ambient = ref.watch(ambientColorProvider);
    final topPad = MediaQuery.paddingOf(context).top;
    ref.listen(builtinDrinksProvider, (previous, next) {
      if (next.hasError && previous?.hasError != true) {
        ref
            .read(toastProvider.notifier)
            .show(context.l10n.loadFailedDescription);
      }
    });

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
                Text(context.l10n.todayDrink,
                    style: AppType.serifZh(size: 24, height: 1.2)),
              ]),
              GlassCircleButton(
                key: const ValueKey('create_cocktail'),
                icon: PhosphorIcons.plus(PhosphorIconsStyle.bold),
                appleSystemImageName: 'plus',
                size: 44,
                iconSize: 18,
                iconColor: Colors.white,
                semanticLabel: context.l10n.uploadCocktail,
                onTap: () {
                  if (!ref.read(userProvider).isLoggedIn) {
                    ref
                        .read(toastProvider.notifier)
                        .show(context.l10n.loginToCreate);
                    context.push('/login');
                    return;
                  }
                  context.push('/upload');
                },
              ),
            ],
          ),
        ),
        // ---- 弧形卡组 ----
        Expanded(
          child: builtin.isLoading
              ? AppLoadingView(themeColor: ambient)
              : list.isEmpty
                  ? AppEmptyView(
                      icon: PhosphorIcons.martini(),
                      title: context.l10n.noCocktailOptions,
                      subtitle: context.l10n.optionsPreparing,
                    )
                  : AnimatedBuilder(
                      animation: deck,
                      builder: (context, child) => GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragStart: (d) =>
                            deck.onDragStart(d.globalPosition.dx),
                        onHorizontalDragUpdate: (d) =>
                            deck.onDragUpdate(d.globalPosition.dx),
                        onHorizontalDragEnd: (details) => deck.onDragEnd(
                          details.primaryVelocity ?? 0,
                          _reduceMotion,
                        ),
                        onHorizontalDragCancel: () =>
                            deck.onDragEnd(0, _reduceMotion),
                        child: ClipRect(
                          child: LayoutBuilder(builder: (context, box) {
                            return _DeckStack(
                              list: list,
                              deck: deck,
                              width: box.maxWidth,
                              onOpen: (drink) {
                                if (deck.suppressClick || deck.spinning) {
                                  return;
                                }
                                _openDetail(drink);
                              },
                            );
                          }),
                        ),
                      ),
                    ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 112),
          child: Text(
            context.l10n.swipeHint,
            style: AppType.sans(
                size: 12, color: Colors.white.withOpacity(.42), height: 1.4),
          ),
        ),
      ]),
      // ---- 抽选结果面板（原型 sheet：bottom 104）----
      Positioned(
        left: 12,
        right: 12,
        bottom: 104,
        child: AnimatedBuilder(
          animation: deck,
          builder: (context, child) {
            Cocktail? sheetDrink;
            for (final drink in list) {
              if (drink.id == deck.sheetId) sheetDrink = drink;
            }
            if (sheetDrink == null) return const SizedBox.shrink();
            return ResultSheet(
              drink: sheetDrink,
              onDetail: () {
                deck.dismissSheet();
                _openDetail(sheetDrink!);
              },
              onRespin: () {
                deck.spin(list, reduceMotion: _reduceMotion);
                _syncResultFeedback();
              },
            );
          },
        ),
      ),
    ]);
  }
}

/// 弧形卡组渲染：只保留当前卡及左右两个预备槽位，远卡先画。
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
  final ValueChanged<Cocktail> onOpen;

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) return const SizedBox.expand();

    final len = list.length;
    final base = deck.pos.round();
    final slots = <_Slot>[];
    for (var k = -2; k <= 2; k++) {
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
            engaged: deck.dragging && s.t.abs() < .5,
            onTap: () => onOpen(s.drink),
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
