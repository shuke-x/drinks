import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../components/glass.dart';
import '../../core/theme/app_typography.dart';
import '../../models/cocktail.dart';
import '../../models/drink_record.dart';
import '../../stores/drink_record_store.dart';
import '../../stores/settings_store.dart';
import 'record_editor_view.dart';
import 'record_widgets.dart';

class RecordDetailView extends ConsumerWidget {
  const RecordDetailView({super.key, required this.id, this.edit = false});
  final String id;
  final bool edit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(drinkRecordsProvider);
    DrinkRecord? record;
    for (final item in state.valueOrNull ?? <DrinkRecord>[]) {
      if (item.id == id) record = item;
    }
    if (record == null) {
      return RecordPage(
          title: recordText(context, '这一杯', 'This glass'),
          child: Center(
              child: state.isLoading
                  ? const CupertinoActivityIndicator()
                  : Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(recordText(
                          context,
                          state.hasError ? '记录读取失败' : '当前账户下没有这条记录',
                          state.hasError
                              ? 'Could not load record'
                              : 'No record for this account')),
                      if (state.hasError)
                        CupertinoButton(
                            onPressed: () =>
                                ref.invalidate(drinkRecordsProvider),
                            child: Text(recordText(context, '重试', 'Retry'))),
                    ])));
    }
    final item = record;
    if (edit) {
      return RecordEditorView(
          key: ValueKey('${ref.watch(recordAccountProvider)}:$id'),
          existing: item);
    }
    return RecordPage(
        title: recordText(context, '这一杯', 'This glass'),
        actions: [
          CupertinoButton(
              onPressed: () => context.push('/records/edit/$id'),
              child: Text(recordText(context, '编辑', 'Edit'))),
        ],
        child: ListView(padding: const EdgeInsets.all(24), children: [
          for (final photo in item.photos) ...[
            ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.memory(base64Decode(photo),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(PhosphorIcons.image()))),
            const SizedBox(height: 24),
          ],
          Text(item.name, style: AppType.serifZh(size: 30)),
          const SizedBox(height: 10),
          Text(
              '${DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).format(item.occurredAt)} · ${sceneLabel(context, item.scene)}',
              style: AppType.sans(size: 14, color: Colors.white70)),
          const SizedBox(height: 20),
          Text(verdictLabel(context, item.verdict),
              style: AppType.serifZh(size: 21, color: const Color(0xFFE8B79B))),
          if (item.note.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(item.note, style: AppType.sans(size: 17, height: 1.6))
          ],
          if (item.scene == DrinkingScene.out) ...[
            if (item.venue.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(item.venue)
            ],
            if (item.price.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(item.price)
            ],
          ],
          if (item.scene == DrinkingScene.home) ...[
            if (item.adjustments.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(recordText(context, '制作调整与下次想法', 'Adjustments & next time'),
                  style: AppType.eyebrow()),
              const SizedBox(height: 10),
              Text(item.adjustments,
                  style: AppType.sans(size: 16, height: 1.6)),
            ],
            if (item.actualRecipe.isNotEmpty) ...[
              const SizedBox(height: 24),
              RecordSurface(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(recordText(context, '这次的配方', 'This time’s recipe'),
                        style: AppType.serifZh(size: 20)),
                    const SizedBox(height: 12),
                    for (final ingredient in item.actualRecipe)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: Text(
                              '${ingredient.n} · ${formatAmount(ingredient, ref.watch(appDataProvider).unit)}',
                              style: AppType.sans(size: 16))),
                  ])),
              const SizedBox(height: 16),
              GlassActionButton(
                  label: recordText(context, '另存为我的配方', 'Save as my recipe'),
                  onTap: () => context.push('/upload?private=true',
                      extra: item.recipeDraft())),
            ],
          ],
          const SizedBox(height: 18),
          GlassActionButton(
              label: recordText(
                  context,
                  item.scene == DrinkingScene.home ? '按这次配方再调一杯' : '再记一次这款酒',
                  item.scene == DrinkingScene.home
                      ? 'Make this version again'
                      : 'Record this drink again'),
              onTap: () => context.push('/records/new', extra: item)),
          if (item.reference != null) ...[
            const SizedBox(height: 14),
            CupertinoButton(
                onPressed: () => context.push('/detail/${item.reference!.id}',
                    extra: item.reference),
                child: Text(
                    recordText(context, '查看参考配方', 'View reference recipe'))),
          ],
          const SizedBox(height: 24),
          if (item.expiresAt != null)
            Text(
                recordText(
                    context,
                    '自动删除时间：${DateFormat.yMd().add_Hm().format(item.expiresAt!.toLocal())}',
                    'Deletes automatically: ${DateFormat.yMd().add_Hm().format(item.expiresAt!.toLocal())}'),
                style: AppType.sans(
                    size: 12, height: 1.5, color: const Color(0xFFB8B5BE))),
          Text(recordText(
              context,
              {
                    'private': '仅自己可见',
                    'pending': '等待公开审核',
                    'published': '审核通过，已公开',
                    'rejected': '审核未通过'
                  }[item.sharingStatus] ??
                  '仅自己可见',
              {
                    'private': 'Private',
                    'pending': 'Awaiting review',
                    'published': 'Approved and public',
                    'rejected': 'Rejected'
                  }[item.sharingStatus] ??
                  'Private')),
          if (item.sharingReason != null) Text(item.sharingReason!),
          if (item.sharingStatus == 'pending' ||
              item.sharingStatus == 'published')
            CupertinoButton(
                onPressed: () async {
                  final account = ref.read(recordAccountProvider),
                      api = ref.read(drinkRecordApiProvider);
                  if (account == null || api == null) return;
                  try {
                    await api.withdraw(account, item);
                    if (context.mounted) {
                      await ref.read(drinkRecordsProvider.notifier).refresh();
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ref.read(toastProvider.notifier).show(recordText(
                          context,
                          '撤回失败，请刷新后重试。',
                          'Could not withdraw. Refresh and retry.'));
                    }
                  }
                },
                child: Text(
                    recordText(context, '撤回公开内容', 'Withdraw public content')))
          else
            CupertinoButton(
                onPressed: () => context.push('/records/share/${item.id}'),
                child: Text(recordText(
                    context, '提交公开审核', 'Submit for publication review'))),
          const SizedBox(height: 30),
          CupertinoButton(
              onPressed: () => _remove(context, ref, item),
              child: Text(recordText(context, '删除这条记录', 'Delete record'),
                  style: const TextStyle(color: Color(0xFFFFB4AB)))),
        ]));
  }

  Future<void> _remove(
      BuildContext context, WidgetRef ref, DrinkRecord item) async {
    final account = ref.read(recordAccountProvider);
    final notifier = ref.read(drinkRecordsProvider.notifier);
    final confirmed = await showCupertinoModalPopup<bool>(
        context: context,
        builder: (sheet) => CupertinoActionSheet(
              title:
                  Text(recordText(context, '删除这条记录？', 'Delete this record?')),
              message: Text(recordText(context, '照片和笔记会一并移除，关联配方不受影响。',
                  'This removes the photo and notes. The reference recipe is unchanged.')),
              actions: [
                CupertinoActionSheetAction(
                    isDestructiveAction: true,
                    onPressed: () => Navigator.pop(sheet, true),
                    child: Text(recordText(context, '删除', 'Delete')))
              ],
              cancelButton: CupertinoActionSheetAction(
                  onPressed: () => Navigator.pop(sheet, false),
                  child: Text(recordText(context, '取消', 'Cancel'))),
            ));
    if (confirmed != true ||
        !context.mounted ||
        account != ref.read(recordAccountProvider)) {
      return;
    }
    try {
      await notifier.remove(item.id);
      if (!context.mounted) return;
      context.canPop() ? context.pop() : context.go('/records');
    } catch (_) {
      if (context.mounted) {
        ref.read(toastProvider.notifier).show(recordText(
            context, '删除失败，请重试。', 'Could not delete. Please retry.'));
      }
    }
  }
}

/// On a recipe, show only this account's tastings, never another user's notes.
class RecipeRecordSection extends ConsumerWidget {
  const RecipeRecordSection({super.key, required this.drink});
  final Cocktail drink;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(recordAccountProvider);
    final state = ref.watch(drinkRecordsProvider);
    final matching = (state.valueOrNull ?? <DrinkRecord>[])
        .where((r) => r.reference?.id == drink.id)
        .toList();
    return RecordSurface(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(recordText(context, '我的品饮记录', 'My tasting notes'),
          style: AppType.serifZh(size: 20)),
      const SizedBox(height: 12),
      if (matching.isNotEmpty) ...[
        Text(
            '${matching.first.name} · ${verdictLabel(context, matching.first.verdict)}',
            style: AppType.sans(size: 15)),
        if (matching.first.adjustments.isNotEmpty)
          Text(matching.first.adjustments,
              style: AppType.sans(size: 14, color: Colors.white70)),
        CupertinoButton(
            onPressed: () => context.push('/records/view/${matching.first.id}'),
            child: Text(recordText(context, '回看上次记录', 'Revisit last time'))),
        if (matching.length > 1)
          CupertinoButton(
              onPressed: () => context.go('/records'),
              child: Text(recordText(context, '查看全部记录', 'View all records'))),
      ] else
        Text(
            recordText(
                context,
                state.hasError ? '记录暂时无法读取。' : '喝过或调过这杯？留下你的感受。',
                state.hasError
                    ? 'Records are temporarily unavailable.'
                    : 'Tried this drink? Keep your first impression.'),
            style: AppType.sans(size: 14, color: Colors.white70)),
      const SizedBox(height: 12),
      GlassActionButton(
          key: const ValueKey('record_this_drink'),
          label: recordText(context, '记录这杯', 'Record this drink'),
          onTap: () => context.push(
              account == null
                  ? '/login?returnTo=/detail/${drink.id}'
                  : '/records/new',
              extra: account == null ? null : drink)),
    ]));
  }
}
