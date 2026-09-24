import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../core/theme/app_theme.dart';
import 'app_secondary_page.dart';
import 'common/glass_circle_button/glass_circle_button.dart';

@Preview(
  name: 'Secondary page · record list',
  group: 'Navigation',
  size: Size(390, 844),
  brightness: Brightness.dark,
)
Widget appSecondaryPagePreview() => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: AppSecondaryPage(
        title: '品饮记录',
        onBack: previewNoop,
        actions: const [
          GlassCircleButton(
            icon: CupertinoIcons.add,
            appleSystemImageName: 'plus',
            semanticLabel: '新增记录',
            onTap: previewNoop,
          ),
        ],
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          itemCount: 3,
          separatorBuilder: (_, __) => const Divider(indent: 72),
          itemBuilder: (_, index) => ListTile(
            leading: const Icon(Icons.local_bar_outlined),
            title: Text(['Negroni', 'Whisky Sour', 'Martini'][index]),
            subtitle: const Text('2026年9月8日 · 自己调的'),
            trailing: const Icon(CupertinoIcons.chevron_forward, size: 16),
          ),
        ),
      ),
    );

void previewNoop() {}
