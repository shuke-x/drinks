import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../components/glass.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/cocktail.dart';

/// 抽选结果面板 —— 原型规格：圆角 30 / blur(30) / 填充 .11 / 描边 .2，
/// sheetUp 弹簧入场（550ms cubic-bezier(.34,1.3,.64,1)）。
class ResultSheet extends StatelessWidget {
  const ResultSheet({
    super.key,
    required this.drink,
    required this.onDetail,
    required this.onRespin,
  });

  final Cocktail drink;
  final VoidCallback onDetail;
  final VoidCallback onRespin;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(drink.id),
      tween: Tween(begin: 1, end: 0),
      duration: const Duration(milliseconds: 550),
      curve: AppMotion.spring,
      builder: (context, v, child) => Transform.translate(
        offset: Offset(0, v * 240),
        child: child,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Colors.white.withOpacity(.11),
              border: Border.all(color: Colors.white.withOpacity(.2)),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                    size: 15, color: Colors.white),
                const SizedBox(width: 8),
                Text('今晚就它了',
                    style: AppType.eyebrow(
                        size: 11.5,
                        color: const Color(0xFFEBEBF5).withOpacity(.85))),
              ]),
              const SizedBox(height: 12),
              Text(drink.zh, style: AppType.serifZh(size: 26, height: 1.2)),
              const SizedBox(height: 9),
              Text(
                '${drink.flavor} 今晚，就让${drink.base}带路。',
                style: AppType.sans(
                    size: 13.5,
                    color: Colors.white.withOpacity(.66),
                    height: 1.6),
              ),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(
                  child: PressScale(
                    onTap: onDetail,
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        color: Colors.white.withOpacity(.95),
                      ),
                      child: Text('查看配方',
                          style: AppType.sans(
                              size: 14.5,
                              weight: FontWeight.w600,
                              color: const Color(0xFF0D0B10),
                              height: 1.0)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PressScale(
                    onTap: onRespin,
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        color: Colors.white.withOpacity(.10),
                        border:
                            Border.all(color: Colors.white.withOpacity(.18)),
                      ),
                      child: Text('再抽一次',
                          style: AppType.sans(
                              size: 14.5,
                              weight: FontWeight.w600,
                              height: 1.0)),
                    ),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
