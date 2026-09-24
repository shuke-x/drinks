import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../components/common/glass_action_button/glass_action_button.dart';
import '../../components/common/glass_circle_button/glass_circle_button.dart';
import '../../components/photo_picker_grid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/cocktail.dart';
import '../../models/drink_record.dart';
import '../../core/network/api_exception.dart';
import '../../core/media/photo_permission.dart';
import '../../stores/drink_record_store.dart';
import '../../stores/settings_store.dart';
import 'record_widgets.dart';

class RecordEditorView extends ConsumerStatefulWidget {
  const RecordEditorView(
      {super.key, this.reference, this.existing, this.template});
  final Cocktail? reference;
  final DrinkRecord? existing;
  final DrinkRecord? template;
  @override
  ConsumerState<RecordEditorView> createState() => _RecordEditorViewState();
}

class _RecipeRow {
  _RecipeRow(RecipeItem item)
      : name = TextEditingController(text: item.n),
        amount =
            TextEditingController(text: item.ml?.toString() ?? item.t ?? '');
  final TextEditingController name;
  final TextEditingController amount;
  RecipeItem get value {
    final number = num.tryParse(amount.text.trim());
    return RecipeItem(
        n: name.text.trim(),
        ml: number,
        t: number == null ? amount.text.trim() : null);
  }

  void dispose() {
    name.dispose();
    amount.dispose();
  }
}

class _RecordEditorViewState extends ConsumerState<RecordEditorView> {
  late final TextEditingController _name, _note, _venue, _price, _adjustments;
  late final List<_RecipeRow> _rows;
  late final String? _account;
  late DrinkingScene _scene;
  DrinkVerdict? _verdict;
  late DateTime _date;
  final List<String> _photos = [];
  bool _saving = false, _allowPop = false, _prompting = false;
  late String _initial;
  bool _nameInitialized = false;
  String? _error;

  Cocktail? _reference;
  String get _signature => jsonEncode([
        _name.text,
        _note.text,
        _venue.text,
        _price.text,
        _adjustments.text,
        _scene.name,
        _verdict?.name,
        _date.toIso8601String(),
        _photos,
        _reference?.id,
        for (final row in _rows) [row.name.text, row.amount.text],
      ]);

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _reference =
        existing?.reference ?? widget.template?.reference ?? widget.reference;
    _account = ref.read(recordAccountProvider);
    _name = TextEditingController(
        text: existing?.name ?? widget.template?.name ?? '');
    _note = TextEditingController(text: existing?.note ?? '');
    _venue = TextEditingController(text: existing?.venue ?? '');
    _price = TextEditingController(text: existing?.price ?? '');
    _adjustments = TextEditingController(text: existing?.adjustments ?? '');
    _scene = existing?.scene ?? widget.template?.scene ?? DrinkingScene.home;
    _verdict = existing?.verdict;
    _date = existing?.occurredAt ?? DateTime.now();
    _photos.addAll(existing?.photos ?? []);
    _rows = (existing?.actualRecipe ??
            widget.template?.actualRecipe ??
            _reference?.recipe ??
            [])
        .map(_RecipeRow.new)
        .toList();
    _initial = _signature;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_nameInitialized &&
        widget.existing == null &&
        _name.text.isEmpty &&
        _reference != null) {
      _name.text =
          _reference!.nameFor(Localizations.localeOf(context).languageCode);
      _initial = _signature;
    }
    _nameInitialized = true;
  }

  @override
  void dispose() {
    for (final controller in [_name, _note, _venue, _price, _adjustments]) {
      controller.dispose();
    }
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _close() async {
    if (_saving || _prompting) return;
    if (_signature != _initial) {
      _prompting = true;
      final discard = await showCupertinoModalPopup<bool>(
          context: context,
          builder: (sheet) => CupertinoActionSheet(
                title: Text(recordText(context, '放弃这次修改？', 'Discard changes?')),
                actions: [
                  CupertinoActionSheetAction(
                      isDestructiveAction: true,
                      onPressed: () => Navigator.pop(sheet, true),
                      child: Text(recordText(context, '放弃修改', 'Discard')))
                ],
                cancelButton: CupertinoActionSheetAction(
                    onPressed: () => Navigator.pop(sheet, false),
                    child: Text(recordText(context, '继续记录', 'Keep editing'))),
              ));
      _prompting = false;
      if (discard != true || !mounted) return;
    }
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.canPop() ? context.pop() : context.go('/records');
    });
  }

  Future<void> _pickPhoto() async {
    if (!await ensurePhotoPermission(context)) return;
    try {
      final images = await ImagePicker().pickMultiImage(
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 75,
          requestFullMetadata: false);
      if (images.isEmpty) return;
      final added = <String>[];
      for (final image in images) {
        added.add(base64Encode(await image.readAsBytes()));
      }
      if (!mounted) return;
      final all = [..._photos, ...added];
      if (all.length > 9 ||
          all.fold<int>(0, (sum, image) => sum + image.length) > 2700000) {
        setState(() => _error = recordText(
            context,
            '最多选择 9 张照片，照片总大小请控制在 2 MB 内。',
            'Choose up to 9 photos, totaling at most 2 MB.'));
        return;
      }
      setState(() {
        _photos.addAll(added);
        _error = null;
      });
    } on PlatformException catch (error) {
      if (mounted &&
          {'photo_access_denied', 'photo_access_restricted'}
              .contains(error.code)) {
        await showPhotoPermissionDialog(context);
        return;
      }
      if (mounted) {
        setState(() => _error = recordText(context, '无法读取照片，请重新选择。',
            'Could not read the photo. Please try again.'));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = recordText(context, '无法读取照片，请重新选择。',
            'Could not read the photo. Please try again.'));
      }
    }
  }

  Future<void> _pickDate() async {
    var pending = _date;
    final selected = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (sheetContext) => CupertinoPopupSurface(
        child: ColoredBox(
          color: const Color(0xFF18151B),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 330,
              child: Column(
                children: [
                  SizedBox(
                    height: 52,
                    child: Row(
                      children: [
                        CupertinoButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: Text(recordText(context, '取消', 'Cancel')),
                        ),
                        Expanded(
                          child: Text(
                            recordText(context, '品饮日期', 'Date'),
                            textAlign: TextAlign.center,
                            style:
                                AppType.sans(size: 15, weight: FontWeight.w600),
                          ),
                        ),
                        CupertinoButton(
                          onPressed: () => Navigator.pop(sheetContext, pending),
                          child: Text(recordText(context, '完成', 'Done')),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                      height: 1, color: Colors.white.withValues(alpha: .10)),
                  Expanded(
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.dateAndTime,
                      initialDateTime: _date,
                      maximumDate: DateTime.now(),
                      use24hFormat: true,
                      onDateTimeChanged: (value) => pending = value,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (selected != null && mounted) setState(() => _date = selected);
  }

  Future<void> _linkRecipe() async {
    final drink = await context.push<Cocktail>('/search?select=recipe');
    if (drink == null || !mounted) return;
    setState(() {
      _reference = drink;
      if (_name.text.trim().isEmpty) {
        _name.text =
            drink.nameFor(Localizations.localeOf(context).languageCode);
      }
      // Keep manually entered quantities; only seed a previously empty recipe.
      if (_rows.isEmpty) _rows.addAll(drink.recipe.map(_RecipeRow.new));
    });
  }

  late final String _recordId =
      widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> _save() async {
    if (_saving) return;
    if (_name.text.trim().isEmpty || _verdict == null) {
      setState(() => _error = recordText(context, '填一个酒名，再选一个感受，就可以保存。',
          'Enter a drink name and choose your impression.'));
      return;
    }
    if (_rows.any((row) {
      final number = num.tryParse(row.amount.text.trim());
      return row.name.text.trim().isNotEmpty &&
          number != null &&
          (!number.isFinite || number <= 0);
    })) {
      setState(() => _error = recordText(context, '材料用量需要大于零。',
          'Ingredient amounts must be greater than zero.'));
      return;
    }
    if (_account == null || ref.read(recordAccountProvider) != _account) {
      setState(() => _error = recordText(context, '账户已变化，请返回后重新打开记录。',
          'Your account changed. Reopen this record to continue.'));
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final record = DrinkRecord(
      id: _recordId,
      version: widget.existing?.version,
      name: _name.text.trim(),
      occurredAt: _date,
      scene: _scene,
      verdict: _verdict!,
      note: _note.text.trim(),
      venue: _venue.text.trim(),
      price: _price.text.trim(),
      adjustments: _adjustments.text.trim(),
      photosBase64: List.of(_photos),
      reference: _reference,
      actualRecipe: _rows
          .where((row) => row.name.text.trim().isNotEmpty)
          .map((row) => row.value)
          .toList(),
    );
    try {
      await ref.read(drinkRecordsProvider.notifier).save(record);
      if (!mounted) return;
      if (ref.read(recordAccountProvider) != _account) return;
      ref
          .read(toastProvider.notifier)
          .show(recordText(context, '已记下这一杯', 'Memory saved'));
      setState(() => _allowPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.canPop() ? context.pop() : context.go('/records');
      });
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.code == 409 || error.code == 1409
            ? recordText(context, '这条记录已在其他地方修改。当前输入仍保留，请复制需要的内容，返回刷新后再编辑。',
                'This record changed elsewhere. Keep a copy of your edits, then go back and refresh before editing again.')
            : recordText(context, '保存失败，输入仍保留在此页面。请恢复网络后重试。',
                'Could not save. Your input remains on this page. Reconnect and retry.'));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = recordText(context, '保存失败，你的输入仍保留在这里，请重试。',
            'Could not save. Your changes are still here; please retry.'));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(
    String zh,
    String en,
    TextEditingController controller, {
    String? placeholder,
    int lines = 1,
    TextInputType? keyboardType,
  }) =>
      _formRow(
        recordText(context, zh, en),
        Semantics(
            label: recordText(context, zh, en),
            child: _input(controller,
                placeholder: placeholder,
                lines: lines,
                keyboardType: keyboardType)),
      );

  Widget _formRow(String label, Widget content) {
    final large = MediaQuery.textScalerOf(context).scale(13) > 20;
    final title =
        Text(label, style: AppType.sans(size: 13, weight: FontWeight.w600));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: large
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [title, const SizedBox(height: 10), content])
          : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                  width: 64,
                  child: Padding(
                      padding: const EdgeInsets.only(top: 12), child: title)),
              const SizedBox(width: 10),
              Expanded(child: content),
            ]),
    );
  }

  Widget _input(
    TextEditingController controller, {
    String? placeholder,
    int lines = 1,
    TextInputType? keyboardType,
  }) =>
      CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        maxLines: lines,
        minLines: lines > 1 ? 3 : 1,
        keyboardType: keyboardType,
        textInputAction:
            lines > 1 ? TextInputAction.newline : TextInputAction.next,
        style: AppType.sans(size: 14, height: lines > 1 ? 1.6 : 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemFill.darkColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: .12)),
        ),
        clearButtonMode: lines == 1
            ? OverlayVisibilityMode.editing
            : OverlayVisibilityMode.never,
        onChanged: (_) => setState(() {}),
      );

  Widget _section({required List<Widget> children}) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: .10)),
            ),
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(children: children))),
      );

  @override
  Widget build(BuildContext context) {
    final activeAccount = ref.watch(recordAccountProvider);
    if (activeAccount == null || activeAccount != _account) {
      return RecordPage(
          title: recordText(context, '记录这杯', 'Record a drink'),
          child: Center(
              child: CupertinoButton(
                  onPressed: () => context.go('/login?returnTo=/records/new'),
                  child: Text(
                      recordText(context, '登录后记录', 'Sign in to record')))));
    }
    return PopScope(
      canPop: _allowPop || (!_saving && _signature == _initial),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: RecordPage(
        title: recordText(context, widget.existing == null ? '记录这杯' : '编辑记录',
            widget.existing == null ? 'Record a drink' : 'Edit record'),
        onBack: _close,
        actions: [
          GlassActionButton(
            key: const ValueKey('save_record'),
            label: _saving
                ? recordText(context, '保存中', 'Saving')
                : recordText(context, '保存', 'Save'),
            prominent: true,
            width: 96,
            height: 44,
            onTap: _saving ? null : _save,
          ),
        ],
        child: AbsorbPointer(
            absorbing: _saving,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                  top: 12,
                  bottom: 24 + MediaQuery.viewInsetsOf(context).bottom),
              children: [
                _section(
                  children: [
                    _field('酒名', 'Name', _name,
                        placeholder:
                            recordText(context, '输入酒名', 'Enter a drink name')),
                    _formRow(
                      recordText(context, '场景', 'Scene'),
                      CupertinoSlidingSegmentedControl<DrinkingScene>(
                        groupValue: _scene,
                        children: {
                          for (final scene in DrinkingScene.values)
                            scene: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 7),
                              child: Text(sceneLabel(context, scene),
                                  style: AppType.sans(size: 12.5)),
                            ),
                        },
                        onValueChanged: (value) {
                          if (value != null) setState(() => _scene = value);
                        },
                      ),
                    ),
                    _formRow(
                      recordText(context, '日期', 'Date'),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: AlignmentDirectional.centerStart,
                        onPressed: _pickDate,
                        child: Text(DateFormat.yMMMd(
                                Localizations.localeOf(context).toLanguageTag())
                            .add_Hm()
                            .format(_date)),
                      ),
                    ),
                    _formRow(
                        recordText(context, '配方', 'Recipe'),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _linkRecipe,
                          child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                  color: Colors.white.withValues(
                                      alpha: _reference == null ? .04 : .12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: _reference == null
                                          ? Colors.transparent
                                          : const Color(0xFFBFA184))),
                              child: Row(
                                children: [
                                  Icon(
                                      _reference == null
                                          ? CupertinoIcons.link
                                          : CupertinoIcons
                                              .checkmark_circle_fill,
                                      color: _reference == null
                                          ? Colors.white70
                                          : const Color(0xFFE0C2A4),
                                      size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(_reference == null
                                        ? recordText(context, '关联已有配方（可选）',
                                            'Link a recipe (optional)')
                                        : recordText(
                                            context,
                                            '已关联：${_reference!.nameFor(Localizations.localeOf(context).languageCode)}',
                                            'Linked: ${_reference!.nameFor(Localizations.localeOf(context).languageCode)}')),
                                  ),
                                  const Icon(CupertinoIcons.chevron_forward,
                                      size: 15),
                                ],
                              )),
                        )),
                  ],
                ),
                if (_scene == DrinkingScene.out) ...[
                  _section(
                    children: [
                      _field('酒吧', 'Bar', _venue,
                          placeholder: recordText(context, '可选', 'Optional')),
                      _field('价格', 'Price', _price, placeholder: 'HK\$ 120'),
                    ],
                  ),
                ] else ...[
                  _section(
                    children: [
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(recordText(context, '材料', 'Ingredients'),
                                    style: AppType.sans(
                                        size: 14,
                                        weight: FontWeight.w600,
                                        color: AppColors.textPrimary)),
                                Semantics(
                                  button: true,
                                  label: recordText(
                                      context, '添加材料', 'Add ingredient'),
                                  child: CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: () => setState(() => _rows.add(
                                          _RecipeRow(const RecipeItem(n: '')))),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 11, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: .10),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          border: Border.all(
                                              color: Colors.white
                                                  .withValues(alpha: .18)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(CupertinoIcons.add,
                                                size: 14,
                                                color: AppColors.textPrimary),
                                            const SizedBox(width: 5),
                                            Text(
                                                recordText(context, '添加材料',
                                                    'Add ingredient'),
                                                style: AppType.sans(
                                                    size: 12.5,
                                                    weight: FontWeight.w600,
                                                    color:
                                                        AppColors.textPrimary)),
                                          ],
                                        ),
                                      )),
                                ),
                              ])),
                      for (final row in _rows)
                        Padding(
                            key: ObjectKey(row),
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                            child: Row(children: [
                              Expanded(
                                  flex: 3,
                                  child: _input(row.name,
                                      placeholder: recordText(
                                          context, '材料', 'Ingredient'))),
                              const SizedBox(width: 8),
                              Expanded(
                                  flex: 2,
                                  child: _input(row.amount,
                                      placeholder:
                                          recordText(context, '用量', 'Amount'))),
                              const SizedBox(width: 8),
                              GlassCircleButton(
                                  icon: CupertinoIcons.minus,
                                  appleSystemImageName: 'minus',
                                  size: 34,
                                  iconSize: 14,
                                  semanticLabel: recordText(
                                      context, '移除材料', 'Remove ingredient'),
                                  onTap: () {
                                    setState(() => _rows.remove(row));
                                    row.dispose();
                                  }),
                            ])),
                      _field('下次调整', 'Next time', _adjustments,
                          lines: 3,
                          placeholder: recordText(context, '可选', 'Optional')),
                    ],
                  ),
                ],
                _section(
                  children: [
                    _formRow(
                      recordText(context, '照片', 'Photos'),
                      PhotoPickerGrid(
                        itemCount: _photos.length,
                        itemSize: 72,
                        onAdd: _pickPhoto,
                        itemBuilder: (context, i) => PhotoPickerTile(
                          size: 72,
                          semanticLabel:
                              recordText(context, '移除照片', 'Remove photo'),
                          onRemove: () => setState(() => _photos.removeAt(i)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(base64Decode(_photos[i]),
                                fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                _section(
                  children: [
                    _formRow(
                      recordText(context, '评价', 'Rating'),
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoSlidingSegmentedControl<DrinkVerdict>(
                          groupValue: _verdict,
                          thumbColor: switch (_verdict) {
                            DrinkVerdict.loved => const Color(0xFF466554),
                            DrinkVerdict.liked => const Color(0xFF766744),
                            DrinkVerdict.notForMe => const Color(0xFF754D50),
                            null => const Color(0xFF414047),
                          },
                          children: {
                            for (final verdict in DrinkVerdict.values)
                              verdict: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 8),
                                child: Text(verdictLabel(context, verdict),
                                    style: AppType.sans(size: 12)),
                              ),
                          },
                          onValueChanged: (value) =>
                              setState(() => _verdict = value),
                        ),
                      ),
                    ),
                    _field('笔记', 'Notes', _note,
                        lines: 3,
                        placeholder: recordText(context, '味道、香气，或想记住的细节',
                            'Flavor, aroma, or anything to remember')),
                  ],
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                    child: Text(_error!,
                        style: const TextStyle(color: Color(0xFFFFB4AB))),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
                  child: Text(
                    recordText(context, '记录和照片仅保留 7 天，到期后服务器会自动删除；编辑不会延长保留时间。',
                        'Records and photos are kept for 7 days, then automatically deleted from the server. Editing does not extend this period.'),
                    textAlign: TextAlign.left,
                    style: AppType.sans(
                        size: 12, height: 1.5, color: const Color(0xFFB8B5BE)),
                  ),
                ),
              ],
            )),
      ),
    );
  }
}
