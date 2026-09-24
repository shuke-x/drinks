import 'package:flutter/material.dart';

/// Code-native visual studies for the flavor recommendation redesign.
///
/// These widgets intentionally stay isolated from the production route until a
/// direction is selected. They contain no business logic and are safe to
/// delete after the chosen direction is implemented.
enum RecommendationDesignOption { editorialIndex, moodGallery }

enum RecommendationDesignScreen { picker, results }

class RecommendationDesignStudy extends StatelessWidget {
  const RecommendationDesignStudy({
    super.key,
    required this.option,
    required this.screen,
  });

  final RecommendationDesignOption option;
  final RecommendationDesignScreen screen;

  @override
  Widget build(BuildContext context) {
    return switch ((option, screen)) {
      (
        RecommendationDesignOption.editorialIndex,
        RecommendationDesignScreen.picker,
      ) =>
        const _EditorialPicker(),
      (
        RecommendationDesignOption.editorialIndex,
        RecommendationDesignScreen.results,
      ) =>
        const _EditorialResults(),
      (
        RecommendationDesignOption.moodGallery,
        RecommendationDesignScreen.picker,
      ) =>
        const _GalleryPicker(),
      (
        RecommendationDesignOption.moodGallery,
        RecommendationDesignScreen.results,
      ) =>
        const _GalleryResults(),
    };
  }
}

const _ink = Color(0xFF0D0E0F);
const _warmInk = Color(0xFF11100F);
const _paper = Color(0xFFF0EFEA);
const _secondary = Color(0xFFA8A8A3);
const _hairline = Color(0x24FFFFFF);
const _sage = Color(0xFF8FA69B);
const _fog = Color(0xFF8999A2);
const _clay = Color(0xFFA08C7D);

const _flavors = <({String title, String note, Color color, IconData icon})>[
  (title: '清爽解渴', note: '轻盈、明亮，适合慢慢喝', color: _fog, icon: Icons.air_rounded),
  (
    title: '酸甜开胃',
    note: '酸度活泼，甜味恰到好处',
    color: _clay,
    icon: Icons.water_drop_outlined
  ),
  (
    title: '果香明显',
    note: '饱满果味，第一口就很鲜明',
    color: Color(0xFF9D8589),
    icon: Icons.local_florist_outlined
  ),
  (title: '茶香淡雅', note: '克制清雅，留一点草本余韵', color: _sage, icon: Icons.spa_outlined),
  (
    title: '浓郁顺滑',
    note: '醇厚柔和，适合夜色渐深时',
    color: Color(0xFF8E8495),
    icon: Icons.nightlight_outlined
  ),
];

const _drinks = <({
  String zh,
  String en,
  String note,
  String meta,
  Color color,
})>[
  (
    zh: '青柠金菲士',
    en: 'Lime Gin Fizz',
    note: '青柠与苏打带来干净明亮的气泡感。',
    meta: '金酒  ·  16% ABV',
    color: Color(0xFF668F89),
  ),
  (
    zh: '乌龙月光',
    en: 'Oolong Moonlight',
    note: '焙火乌龙安静展开，草本香气收住甜感。',
    meta: '朗姆酒  ·  18% ABV',
    color: Color(0xFF7E8A6E),
  ),
  (
    zh: '白桃茉莉',
    en: 'White Peach Jasmine',
    note: '成熟白桃的汁感与茉莉茶香轻轻叠在一起。',
    meta: '伏特加  ·  14% ABV',
    color: Color(0xFF9B7D80),
  ),
  (
    zh: '金桂威士忌酸',
    en: 'Osmanthus Whiskey Sour',
    note: '柔和甜味包住鲜明酸度，尾段留有桂花香。',
    meta: '威士忌  ·  21% ABV',
    color: Color(0xFF92795F),
  ),
  (
    zh: '莓果暮色',
    en: 'Berry Dusk',
    note: '莓果酸甜之间，留有轻微杜松子气息。',
    meta: '金酒  ·  17% ABV',
    color: Color(0xFF846A76),
  ),
];

class _EditorialPicker extends StatelessWidget {
  const _EditorialPicker();

  @override
  Widget build(BuildContext context) {
    return _StudyScaffold(
      background: _ink,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 28, 20, 118),
            sliver: SliverList.list(
              children: [
                const _EditorialHeader(
                  kicker: 'TONIGHT',
                  title: '现在，想喝什么？',
                  note: '不用先知道酒名。\n从此刻想要的感觉开始。',
                ),
                const SizedBox(height: 38),
                Text(
                  '选择一种风味',
                  style: _sans(13, color: _secondary, weight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                for (final flavor in _flavors)
                  _EditorialFlavorRow(flavor: flavor),
                const _EditorialFlavorRow(
                  flavor: (
                    title: '随便帮我选',
                    note: '把选择交给今晚',
                    color: Color(0xFFAAA49A),
                    icon: Icons.auto_awesome_outlined,
                  ),
                  surprise: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorialHeader extends StatelessWidget {
  const _EditorialHeader({
    required this.kicker,
    required this.title,
    required this.note,
  });

  final String kicker;
  final String title;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(kicker,
            style: _sans(11,
                color: _secondary, weight: FontWeight.w600, spacing: 2.2)),
        const SizedBox(height: 14),
        Text(title, style: _serif(34, height: 1.18)),
        const SizedBox(height: 14),
        Text(note, style: _sans(16, color: _secondary, height: 1.55)),
      ],
    );
  }
}

class _EditorialFlavorRow extends StatelessWidget {
  const _EditorialFlavorRow({required this.flavor, this.surprise = false});

  final ({String title, String note, Color color, IconData icon}) flavor;
  final bool surprise;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${flavor.title}，${flavor.note}',
      child: Container(
        constraints: const BoxConstraints(minHeight: 76),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _hairline, width: .7)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: surprise
                    ? Icon(flavor.icon, size: 19, color: flavor.color)
                    : Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: flavor.color,
                          shape: BoxShape.circle,
                        ),
                      ),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(flavor.title, style: _serif(21)),
                  const SizedBox(height: 4),
                  Text(flavor.note, style: _sans(13, color: _secondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 21, color: Color(0x99FFFFFF)),
          ],
        ),
      ),
    );
  }
}

class _EditorialResults extends StatelessWidget {
  const _EditorialResults();

  @override
  Widget build(BuildContext context) {
    return _StudyScaffold(
      background: _ink,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: _ResultsNav()),
          SliverPadding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 20, 22),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('清爽解渴', style: _serif(34)),
                  const SizedBox(height: 8),
                  Text('轻盈、明亮，适合慢慢喝', style: _sans(16, color: _secondary)),
                  const SizedBox(height: 30),
                  Text('适合今晚',
                      style: _sans(13,
                          color: _secondary, weight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 40),
            sliver: SliverList.builder(
              itemCount: _drinks.length,
              itemBuilder: (context, index) =>
                  _EditorialDrinkRow(drink: _drinks[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorialDrinkRow extends StatelessWidget {
  const _EditorialDrinkRow({required this.drink});

  final ({String zh, String en, String note, String meta, Color color}) drink;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _hairline, width: .7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _AbstractDrinkArt(
              color: drink.color, width: 66, height: 82, radius: 8),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(drink.zh, style: _serif(20)),
                const SizedBox(height: 2),
                Text(drink.en,
                    style: _sans(13,
                        color: const Color(0xFFD1D0CC),
                        weight: FontWeight.w500)),
                const SizedBox(height: 7),
                Text(drink.note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _sans(12, color: _secondary)),
                const SizedBox(height: 5),
                Text(drink.meta,
                    style: _sans(11,
                        color: const Color(0xFF777975),
                        weight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded,
              size: 20, color: Color(0x80FFFFFF)),
        ],
      ),
    );
  }
}

class _GalleryPicker extends StatelessWidget {
  const _GalleryPicker();

  @override
  Widget build(BuildContext context) {
    return _StudyScaffold(
      background: _warmInk,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 27, 20, 118),
            sliver: SliverList.list(
              children: [
                const _EditorialHeader(
                  kicker: 'MOOD MENU',
                  title: '今晚的味道',
                  note: '选一种感觉，酒名稍后再说。',
                ),
                const SizedBox(height: 28),
                _MoodBand(flavor: _flavors[0], height: 174, featured: true),
                const SizedBox(height: 10),
                _MoodBand(flavor: _flavors[1], height: 94),
                const SizedBox(height: 10),
                _MoodBand(flavor: _flavors[2], height: 94, reverse: true),
                const SizedBox(height: 10),
                _MoodBand(flavor: _flavors[3], height: 94),
                const SizedBox(height: 10),
                _MoodBand(flavor: _flavors[4], height: 94, reverse: true),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(minHeight: 52),
                  alignment: AlignmentDirectional.centerStart,
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome_outlined,
                          size: 18, color: Color(0xFFC4BDB0)),
                      const SizedBox(width: 12),
                      Text('随便帮我选',
                          style: _sans(15,
                              color: const Color(0xFFD7D3CB),
                              weight: FontWeight.w600)),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 19, color: Color(0x99FFFFFF)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodBand extends StatelessWidget {
  const _MoodBand({
    required this.flavor,
    required this.height,
    this.featured = false,
    this.reverse = false,
  });

  final ({String title, String note, Color color, IconData icon}) flavor;
  final double height;
  final bool featured;
  final bool reverse;

  @override
  Widget build(BuildContext context) {
    final art = Expanded(
      flex: featured ? 5 : 3,
      child: _AbstractDrinkArt(
        color: flavor.color,
        height: height,
        radius: 0,
        detailed: featured,
      ),
    );
    final copy = Expanded(
      flex: featured ? 4 : 5,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 17),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(flavor.title, style: _serif(featured ? 24 : 19)),
            const SizedBox(height: 6),
            Text(flavor.note,
                maxLines: featured ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: _sans(12, color: const Color(0xFFB1AEA7), height: 1.4)),
          ],
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(featured ? 20 : 13),
      child: ColoredBox(
        color: const Color(0xFF1B1A18),
        child: SizedBox(
          height: height,
          child: Row(children: reverse ? [copy, art] : [art, copy]),
        ),
      ),
    );
  }
}

class _GalleryResults extends StatelessWidget {
  const _GalleryResults();

  @override
  Widget build(BuildContext context) {
    return _StudyScaffold(
      background: _warmInk,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: _ResultsNav()),
          SliverPadding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 20, 26),
            sliver: SliverToBoxAdapter(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                      child: Text('清爽\n解渴', style: _serif(40, height: 1.05))),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: SizedBox(
                      width: 142,
                      child: Text('轻盈、明亮，\n适合慢慢喝。',
                          textAlign: TextAlign.end,
                          style: _sans(14, color: _secondary, height: 1.5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 40),
            sliver: SliverList.separated(
              itemCount: _drinks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _GalleryDrinkRow(
                drink: _drinks[index],
                reverse: index.isOdd,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryDrinkRow extends StatelessWidget {
  const _GalleryDrinkRow({required this.drink, required this.reverse});

  final ({String zh, String en, String note, String meta, Color color}) drink;
  final bool reverse;

  @override
  Widget build(BuildContext context) {
    final art = _AbstractDrinkArt(
        color: drink.color,
        width: 112,
        height: 130,
        radius: 13,
        detailed: true);
    final copy = Expanded(
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: reverse ? 0 : 17,
          end: reverse ? 17 : 0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(drink.zh, style: _serif(22)),
            const SizedBox(height: 3),
            Text(drink.en,
                style: _sans(12,
                    color: const Color(0xFFC9C4BA), weight: FontWeight.w600)),
            const SizedBox(height: 10),
            Text(drink.note,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _sans(12, color: _secondary, height: 1.45)),
            const SizedBox(height: 9),
            Text(drink.meta,
                style: _sans(11,
                    color: const Color(0xFF77736D), weight: FontWeight.w600)),
          ],
        ),
      ),
    );
    return Container(
      constraints: const BoxConstraints(minHeight: 130),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x18FFFFFF))),
      ),
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: reverse ? [copy, art] : [art, copy]),
    );
  }
}

class _ResultsNav extends StatelessWidget {
  const _ResultsNav();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 7, 20, 0),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0x10FFFFFF),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0x1FFFFFFF)),
                  ),
                  child: const Icon(Icons.chevron_left_rounded,
                      color: _paper, size: 23),
                ),
              ),
            ),
            const Spacer(),
            Text('风味推荐',
                style: _sans(13, color: _secondary, weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _AbstractDrinkArt extends StatelessWidget {
  const _AbstractDrinkArt({
    required this.color,
    required this.height,
    required this.radius,
    this.width,
    this.detailed = false,
  });

  final Color color;
  final double? width;
  final double height;
  final double radius;
  final bool detailed;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(painter: _DrinkArtPainter(color, detailed)),
      ),
    );
  }
}

class _DrinkArtPainter extends CustomPainter {
  const _DrinkArtPainter(this.color, this.detailed);

  final Color color;
  final bool detailed;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: .76), const Color(0xFF1C1C1C)],
        ).createShader(rect),
    );
    canvas.drawCircle(
      Offset(size.width * .72, size.height * .2),
      size.shortestSide * .38,
      Paint()..color = Colors.white.withValues(alpha: .06),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .48, size.height * .52),
        width: size.width * (detailed ? .48 : .42),
        height: size.height * .18,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(alpha: .58),
    );
    final stemTop = size.height * .6;
    canvas.drawLine(
      Offset(size.width * .48, stemTop),
      Offset(size.width * .48, size.height * .82),
      Paint()
        ..strokeWidth = 1.3
        ..color = Colors.white.withValues(alpha: .5),
    );
    canvas.drawLine(
      Offset(size.width * .35, size.height * .84),
      Offset(size.width * .61, size.height * .84),
      Paint()
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: .5),
    );
    if (detailed) {
      final garnish = Path()
        ..moveTo(size.width * .52, size.height * .42)
        ..quadraticBezierTo(size.width * .67, size.height * .32,
            size.width * .74, size.height * .43)
        ..quadraticBezierTo(size.width * .64, size.height * .5,
            size.width * .52, size.height * .42);
      canvas.drawPath(garnish,
          Paint()..color = const Color(0xFFBAC2A9).withValues(alpha: .7));
    }
  }

  @override
  bool shouldRepaint(covariant _DrinkArtPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.detailed != detailed;
  }
}

class _StudyScaffold extends StatelessWidget {
  const _StudyScaffold({required this.background, required this.child});

  final Color background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(.72, -.86),
            radius: 1.05,
            colors: [
              const Color(0xFF353B3B).withValues(alpha: .22),
              background
            ],
          ),
        ),
        child: SafeArea(top: true, bottom: false, child: child),
      ),
    );
  }
}

TextStyle _serif(double size, {double height = 1.2}) => TextStyle(
      fontFamily: 'NotoSerifSC',
      fontSize: size,
      height: height,
      fontWeight: FontWeight.w700,
      color: _paper,
    );

TextStyle _sans(
  double size, {
  Color color = _paper,
  FontWeight weight = FontWeight.w400,
  double height = 1.3,
  double? spacing,
}) =>
    TextStyle(
      fontFamily: 'HankenGrotesk',
      fontFamilyFallback: const ['NotoSerifSC'],
      fontSize: size,
      height: height,
      fontWeight: weight,
      color: color,
      letterSpacing: spacing,
    );
