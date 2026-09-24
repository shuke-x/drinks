import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../components/app_secondary_page.dart';
import '../../core/theme/app_typography.dart';
import '../../stores/drink_record_store.dart';
import 'record_widgets.dart';

class RecordShareView extends ConsumerStatefulWidget {
  const RecordShareView({super.key, required this.id});
  final String id;
  @override
  ConsumerState<RecordShareView> createState() => _RecordShareViewState();
}

class _RecordShareViewState extends ConsumerState<RecordShareView> {
  final _caption = TextEditingController();
  final _selected = <int>{};
  bool _busy = false, _allowPop = false, _closing = false;
  bool get _hasDraft => _caption.text.isNotEmpty || _selected.isNotEmpty;
  Future<void> _close() async {
    if (_busy || _closing) return;
    _closing = true;
    if (_hasDraft) {
      final discard = await showCupertinoDialog<bool>(
          context: context,
          builder: (dialog) => CupertinoAlertDialog(
                title: Text(
                    recordText(context, '放弃分享草稿？', 'Discard sharing draft?')),
                actions: [
                  CupertinoDialogAction(
                      onPressed: () => Navigator.pop(dialog, false),
                      child: Text(recordText(context, '继续编辑', 'Keep editing'))),
                  CupertinoDialogAction(
                      isDestructiveAction: true,
                      onPressed: () => Navigator.pop(dialog, true),
                      child: Text(recordText(context, '放弃', 'Discard')))
                ],
              ));
      if (!mounted) return;
      if (discard != true) {
        _closing = false;
        return;
      }
    }
    if (!mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.canPop() ? context.pop() : context.go('/records');
    });
  }

  String? _error;
  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(drinkRecordsProvider).valueOrNull ?? [];
    final matches =
        items.where((item) => item.id == widget.id && !item.isExpired);
    if (matches.isEmpty) {
      return AppSecondaryPage(
          title: recordText(context, '公开审核', 'Publication review'),
          child: Center(
              child: Text(recordText(
                  context, '记录不存在或已过期', 'Record unavailable or expired'))));
    }
    final item = matches.first;
    return PopScope(
        canPop: _allowPop || (!_busy && !_hasDraft),
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _close();
        },
        child: AppSecondaryPage(
            onBack: _close,
            title: recordText(context, '确认分享内容', 'Review your submission'),
            child: ListView(padding: const EdgeInsets.all(24), children: [
              Text(
                  recordText(
                      context,
                      '以下内容通过审核后可被公开访问。私人笔记、地点、价格和参考配方原文不会自动加入。',
                      'After approval, the content below can be accessed publicly. Private notes, venue, price, and the original reference are not included.'),
                  style: AppType.sans(size: 15, height: 1.5)),
              const SizedBox(height: 20),
              Text(item.name, style: AppType.serifZh(size: 24)),
              const SizedBox(height: 8),
              Text(verdictLabel(context, item.verdict)),
              for (final ingredient in item.actualRecipe)
                Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                        '${ingredient.n} · ${ingredient.ml ?? ingredient.t ?? ''}')),
              const SizedBox(height: 20),
              CupertinoTextField(
                  controller: _caption,
                  onChanged: (_) => setState(() {}),
                  enabled: !_busy,
                  maxLength: 2000,
                  minLines: 3,
                  maxLines: 6,
                  placeholder: recordText(
                      context, '可公开的分享文字（选填）', 'Public caption (optional)'),
                  style: AppType.sans(size: 16)),
              const SizedBox(height: 16),
              if (item.photos.isNotEmpty)
                Text(recordText(context, '选择愿意公开的照片（默认不选）',
                    'Choose photos to make public (none selected by default)')),
              for (var i = 0; i < item.photos.length; i++)
                Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(children: [
                      Image.memory(base64Decode(item.photos[i]),
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(
                              width: 72,
                              height: 72,
                              child: Icon(CupertinoIcons.photo))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(recordText(context, '公开照片 ${i + 1}',
                              'Publish photo ${i + 1}'))),
                      CupertinoSwitch(
                          value: _selected.contains(i),
                          onChanged: _busy
                              ? null
                              : (value) => setState(() => value
                                  ? _selected.add(i)
                                  : _selected.remove(i))),
                    ])),
              const SizedBox(height: 20),
              Text(
                  recordText(context, '记录创建后 7 天自动删除，提交审核不会延长保留期。',
                      'Records are deleted 7 days after creation. Review does not extend retention.'),
                  style: AppType.sans(
                      size: 12, height: 1.5, color: const Color(0xFFB8B5BE))),
              if (_error != null)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(_error!,
                        style: const TextStyle(color: Color(0xFFFFB4AB)))),
              const SizedBox(height: 16),
              CupertinoButton.filled(
                  onPressed: _busy
                      ? null
                      : () async {
                          final account = ref.read(recordAccountProvider),
                              api = ref.read(drinkRecordApiProvider);
                          if (account == null ||
                              api == null ||
                              item.version == null) {
                            return;
                          }
                          setState(() {
                            _busy = true;
                            _error = null;
                          });
                          try {
                            await api.submit(
                                account,
                                item,
                                _caption.text.trim(),
                                _selected.toList()..sort());
                            if (!mounted ||
                                ref.read(recordAccountProvider) != account) {
                              return;
                            }
                            await ref
                                .read(drinkRecordsProvider.notifier)
                                .refresh();
                            if (context.mounted) {
                              setState(() => _allowPop = true);
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) context.pop();
                              });
                            }
                          } catch (_) {
                            if (mounted) {
                              setState(() => _error = recordText(
                                  context,
                                  '提交失败，内容仍保留。若记录已变更或过期，请返回刷新。',
                                  'Could not submit. Your input is preserved. Go back and refresh if the record changed or expired.'));
                            }
                          } finally {
                            if (mounted) setState(() => _busy = false);
                          }
                        },
                  child: _busy
                      ? const CupertinoActivityIndicator()
                      : Text(recordText(context, '确认并提交审核',
                          'Confirm and submit for review'))),
            ])));
  }
}
