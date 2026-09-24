import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../components/common/glass_circle_button/glass_circle_button.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/l10n.dart';
import '../../models/drink_record.dart';
import '../../stores/drink_record_store.dart';
import 'record_widgets.dart';

class RecordsView extends ConsumerStatefulWidget {
  const RecordsView({super.key});
  @override
  ConsumerState<RecordsView> createState() => _RecordsViewState();
}

class _RecordsViewState extends ConsumerState<RecordsView> {
  DrinkingScene? _scene;
  String _query = '';

  void _create() => context.push(ref.read(recordAccountProvider) == null
      ? '/login?returnTo=/records/new'
      : '/records/new');

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(recordAccountProvider);
    final state = ref.watch(drinkRecordsProvider);
    final records = state.valueOrNull ?? [];
    final filtered = records
        .where(
            (r) => (_scene == null || r.scene == _scene) && r.matches(_query))
        .toList();
    return RecordPage(
      title: context.l10n.records,
      onBack: () => context.canPop() ? context.pop() : context.go('/profile'),
      actions: [
        GlassCircleButton(
          key: const ValueKey('new_record'),
          icon: CupertinoIcons.add,
          appleSystemImageName: 'plus',
          size: 38,
          iconSize: 18,
          semanticLabel: recordText(context, '新增记录', 'New record'),
          onTap: _create,
        ),
      ],
      child: CustomScrollView(slivers: [
        if (account != null)
          CupertinoSliverRefreshControl(
              onRefresh: () =>
                  ref.read(drinkRecordsProvider.notifier).refresh()),
        if (account != null)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  CupertinoSearchTextField(
                    placeholder: recordText(context, '搜索记录', 'Search journal'),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<int>(
                      key: const ValueKey('record_scene_tabs'),
                      groupValue: _scene == null
                          ? 0
                          : (_scene == DrinkingScene.home ? 1 : 2),
                      thumbColor: Colors.white.withValues(alpha: .20),
                      backgroundColor: Colors.white.withValues(alpha: .07),
                      onValueChanged: (value) => setState(() {
                        _scene = switch (value) {
                          1 => DrinkingScene.home,
                          2 => DrinkingScene.out,
                          _ => null,
                        };
                      }),
                      children: {
                        0: _SceneTabLabel(recordText(context, '全部', 'All')),
                        1: _SceneTabLabel(
                            sceneLabel(context, DrinkingScene.home)),
                        2: _SceneTabLabel(
                            sceneLabel(context, DrinkingScene.out)),
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (state.isLoading)
          const SliverToBoxAdapter(
              child: Center(child: CupertinoActivityIndicator()))
        else if (state.hasError)
          SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [
                    Icon(CupertinoIcons.tray,
                        size: 36, color: Colors.white.withValues(alpha: .46)),
                    const SizedBox(height: 14),
                    Text(recordText(context, '记录暂时无法读取，原记录未被改动。',
                        'Unable to read your journal. Existing records are unchanged.')),
                  ])))
        else if (filtered.isEmpty)
          SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 54, 24, 24),
              sliver: SliverToBoxAdapter(
                child: Column(children: [
                  Icon(CupertinoIcons.tray,
                      size: 30, color: Colors.white.withValues(alpha: .46)),
                  const SizedBox(height: 14),
                  Text(
                      records.isNotEmpty
                          ? recordText(
                              context, '没有匹配的记录', 'No matching records')
                          : recordText(context, '还没有记录', 'No entries yet'),
                      textAlign: TextAlign.center,
                      style: AppType.sans(
                          size: 15,
                          weight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: .72))),
                ]),
              )),
        if (filtered.isNotEmpty)
          SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  indent: 72,
                  color: Colors.white.withValues(alpha: .10),
                ),
                itemBuilder: (context, index) =>
                    RecordTimelineCard(record: filtered[index]),
              )),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ]),
    );
  }
}

class _SceneTabLabel extends StatelessWidget {
  const _SceneTabLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppType.sans(size: 13, weight: FontWeight.w600),
        ),
      );
}

class RecordTimelineCard extends StatelessWidget {
  const RecordTimelineCard({super.key, required this.record});
  final DrinkRecord record;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: record.name,
        child: CupertinoButton(
          key: ValueKey('record_${record.id}'),
          padding: const EdgeInsets.symmetric(vertical: 12),
          onPressed: () => context.push('/records/view/${record.id}'),
          child: Row(children: [
            _RecordThumbnail(record: record),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.serifZh(size: 18)),
                  const SizedBox(height: 5),
                  Text(
                    '${DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).format(record.occurredAt)} · ${sceneLabel(context, record.scene)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.sans(
                        size: 12.5, color: Colors.white.withValues(alpha: .54)),
                  ),
                  if (record.note.isNotEmpty || record.venue.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      record.note.isNotEmpty ? record.note : record.venue,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.sans(
                          size: 12.5,
                          color: Colors.white.withValues(alpha: .68)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              verdictLabel(context, record.verdict),
              style: AppType.sans(
                  size: 12,
                  weight: FontWeight.w600,
                  color: const Color(0xFFE8B79B)),
            ),
            const SizedBox(width: 5),
            Icon(CupertinoIcons.chevron_forward,
                size: 15, color: Colors.white.withValues(alpha: .34)),
          ]),
        ),
      );
}

class _RecordThumbnail extends StatelessWidget {
  const _RecordThumbnail({required this.record});
  final DrinkRecord record;

  @override
  Widget build(BuildContext context) {
    final placeholder = DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Center(
        child: Icon(PhosphorIcons.martini(),
            size: 20, color: Colors.white.withValues(alpha: .46)),
      ),
    );
    return SizedBox.square(
      dimension: 58,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: record.photos.isEmpty
            ? placeholder
            : Image.memory(
                base64Decode(record.photos.first),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => placeholder,
              ),
      ),
    );
  }
}
