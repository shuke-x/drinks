import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';

/// 卡片主渐变（原型 grad()）：
/// radial-gradient(120% 100% at 28% 0%, {hex}e0 0%, {hex}66 42%, rgba(255,255,255,.05) 100%)
Gradient drinkGrad(Color c) => RadialGradient(
      center: const Alignment(-0.44, -1.0),
      radius: 1.35,
      colors: [
        c.withOpacity(0.88),
        c.withOpacity(0.40),
        Colors.white.withOpacity(0.05),
      ],
      stops: const [0.0, 0.42, 1.0],
    );

/// 酒液光球（原型 orb()）：
/// radial-gradient(circle, {hex}ee 0%, {hex}33 60%, transparent 72%)
Gradient drinkOrb(Color c) => RadialGradient(
      colors: [
        c.withOpacity(0.93),
        c.withOpacity(0.20),
        c.withOpacity(0.0),
      ],
      stops: const [0.0, 0.60, 0.72],
    );

/// 全局氛围主题色（原型 themeColor()）：
/// Home=当前推荐酒色 / Next=居中卡酒色 / System=#5E5CE6 / 详情=该酒色。
/// 各页面负责在自身可见时更新它，AppShell 以 900ms 过渡渲染。
final ambientColorProvider =
    StateProvider<Color>((ref) => AppColors.systemAccent);
