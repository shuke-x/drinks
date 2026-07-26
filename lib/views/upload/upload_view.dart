import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../components/glass.dart';
import '../../components/app_loading_view.dart';
import '../../components/frosted_page_overlay.dart';
import '../../core/theme/app_colors.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_effects.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../models/cocktail.dart';
import '../../data/apis/api_providers.dart';
import '../../stores/cocktail_store.dart';
import '../../stores/deck_store.dart';
import '../../stores/settings_store.dart';

/// 上传 / 编辑酒单覆盖层 —— 原型 uploading 视图。
/// 保存逻辑与原型 saveForm 一致：中文名必填；英文名默认 House Original；
/// abv 20 / tags [私藏] / 用量留空默认 "适量"。
class UploadView extends ConsumerStatefulWidget {
  const UploadView({super.key, this.editId});

  final String? editId;

  @override
  ConsumerState<UploadView> createState() => _UploadViewState();
}

class _IngredientRow {
  final TextEditingController name;
  final TextEditingController amount;
  _IngredientRow({String n = '', String t = ''})
      : name = TextEditingController(text: n),
        amount = TextEditingController(text: t);

  void dispose() {
    name.dispose();
    amount.dispose();
  }
}

class _UploadViewState extends ConsumerState<UploadView> {
  static const _maxImageBytes = 5 * 1024 * 1024;
  final _zh = TextEditingController();
  final _en = TextEditingController();
  final _steps = TextEditingController();
  String _base = '金酒';
  Color _color = AppColors.swatch.first;
  List<_IngredientRow> _rows = [_IngredientRow(), _IngredientRow()];
  final List<XFile> _pickedImages = [];
  bool _saving = false;
  late final DeckController _deckController;

  bool get _isEdit => widget.editId != null;

  @override
  void initState() {
    super.initState();
    _deckController = ref.read(deckControllerProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _deckController.pause();
    });
    // 编辑模式：回填表单（原型 m.edit）
    if (_isEdit) {
      final m = ref
          .read(appDataProvider)
          .mine
          .where((x) => x.id == widget.editId)
          .toList();
      if (m.isNotEmpty) {
        final d = m.first;
        _zh.text = d.zh;
        _en.text = d.en;
        _base = d.base;
        _color = d.themeColor;
        _rows = d.recipe
            .map((r) => _IngredientRow(n: r.n, t: r.t ?? '${r.ml} ml'))
            .toList();
        if (_rows.isEmpty) _rows = [_IngredientRow()];
        _steps.text = d.steps.join('\n');
      }
    }
  }

  @override
  void dispose() {
    _deckController.resume();
    _zh.dispose();
    _en.dispose();
    _steps.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    final files = await ImagePicker().pickMultiImage(
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 82,
    );
    if (!mounted || files.isEmpty) return;
    final accepted = <XFile>[];
    var oversized = 0;
    for (final file in files) {
      final normalized = await _compressToJpeg(file);
      if (normalized == null || await normalized.length() > _maxImageBytes) {
        oversized++;
      } else {
        accepted.add(normalized);
      }
    }
    if (!mounted) return;
    setState(() => _pickedImages.addAll(accepted));
    if (oversized > 0) {
      ref.read(toastProvider.notifier).show('$oversized 张图片超过 5MB，已跳过');
    }
  }

  /// 统一转 JPEG：最长边 2048px、质量 82，兼容 iPhone HEIC 与后端格式限制。
  Future<XFile?> _compressToJpeg(XFile source) async {
    // Web 没有 path_provider 的临时目录实现；浏览器已在选择阶段提供可上传文件，
    // 仍由下方 5MB 校验与服务端限制兜底。
    if (kIsWeb) return source;
    final directory = await getTemporaryDirectory();
    final target = File(
      '${directory.path}/cocktail-${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    return FlutterImageCompress.compressAndGetFile(
      source.path,
      target.path,
      minWidth: 2048,
      minHeight: 2048,
      quality: 82,
      format: CompressFormat.jpeg,
      keepExif: false,
    );
  }

  Widget _imagePreview(XFile image) {
    if (!kIsWeb) {
      return Image.file(File(image.path),
          width: 64, height: 64, fit: BoxFit.cover);
    }
    return FutureBuilder(
      future: image.readAsBytes(),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) return const SizedBox(width: 64, height: 64);
        return Image.memory(bytes, width: 64, height: 64, fit: BoxFit.cover);
      },
    );
  }

  Future<MultipartFile> _multipartFile(XFile file) async {
    if (kIsWeb) {
      return MultipartFile.fromBytes(
        await file.readAsBytes(),
        filename: file.name,
      );
    }
    return MultipartFile.fromFile(file.path, filename: file.name);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_zh.text.trim().isEmpty) {
      ref.read(toastProvider.notifier).show('请先填写中文名');
      return;
    }
    setState(() => _saving = true);
    try {
      final rows = _rows
          .where((r) => r.name.text.trim().isNotEmpty)
          .map((r) => RecipeItem(
                n: r.name.text.trim(),
                t: r.amount.text.trim().isEmpty ? '适量' : r.amount.text.trim(),
              ))
          .toList();
      final hexColor =
          '#${_color.value.toRadixString(16).substring(2).toUpperCase()}';
      final images = await Future.wait(_pickedImages.map((file) async =>
          ref.read(uploadApiProvider).uploadImage(await _multipartFile(file))));
      if (!mounted) return;
      final item = Cocktail(
        id: widget.editId ?? 'my-${DateTime.now().millisecondsSinceEpoch}',
        zh: _zh.text.trim(),
        en: _en.text.trim().isEmpty ? 'House Original' : _en.text.trim(),
        base: _base,
        abv: 20,
        color: hexColor,
        images: images,
        tags: const ['私藏'],
        glass: '依你所好',
        garnish: '自由发挥',
        flavor: '来自你自己的酒单。',
        story: '这一杯由你定义。',
        recipe: rows,
        steps:
            _steps.text.split('\n').where((s) => s.trim().isNotEmpty).toList(),
      );
      ref.read(appDataProvider.notifier).upsert(item, editId: widget.editId);
      ref.read(toastProvider.notifier).show(_isEdit ? '已更新' : '已加入我的酒单');
      context.pop();
    } on ApiException catch (error) {
      if (mounted) ref.read(toastProvider.notifier).show(error.message);
    } catch (_) {
      if (mounted) ref.read(toastProvider.notifier).show('上传失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: Stack(children: [
        FrostedPageOverlay(
          blur: 14,
          opacity: .74,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                topPad + 12,
                AppSpacing.gutter,
                40 + MediaQuery.viewInsetsOf(context).bottom),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---- 头部 ----
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('NEW RECIPE',
                                style: AppType.eyebrow(
                                    size: 11,
                                    tracking: .18,
                                    color: Colors.white.withOpacity(.42))),
                            const SizedBox(height: 7),
                            Text('上传酒单',
                                style: AppType.serifZh(size: 26, height: 1.2)),
                          ]),
                      GlassCircleButton(
                        icon: PhosphorIcons.x(PhosphorIconsStyle.bold),
                        size: 38,
                        iconSize: 15,
                        iconColor: Colors.white,
                        onTap: () => context.pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // ---- 基本信息 ----
                  RiseIn(
                    child: GlassCard(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _input(_zh, '中文名，如 山楂古典'),
                            const SizedBox(height: 9),
                            _input(_en, '英文名，如 Hawthorn Old Fashioned'),
                            const SizedBox(height: 16),
                            Text('基酒',
                                style: AppType.sans(
                                    size: 11.5,
                                    weight: FontWeight.w500,
                                    color: Colors.white.withOpacity(.5),
                                    height: 1.0)),
                            const SizedBox(height: 9),
                            Wrap(spacing: 7, runSpacing: 7, children: [
                              for (final b in kCategories.skip(1))
                                GlassChip(
                                  label: b,
                                  selected: _base == b,
                                  fontSize: 12,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 13, vertical: 9),
                                  onTap: () => setState(() => _base = b),
                                ),
                            ]),
                            const SizedBox(height: 16),
                            Text('主题色',
                                style: AppType.sans(
                                    size: 11.5,
                                    weight: FontWeight.w500,
                                    color: Colors.white.withOpacity(.5),
                                    height: 1.0)),
                            const SizedBox(height: 9),
                            Row(children: [
                              for (final c in AppColors.swatch)
                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: GestureDetector(
                                    onTap: () => setState(() => _color = c),
                                    child: AnimatedScale(
                                      scale: _color == c ? 1.15 : 1,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: AppMotion.spring,
                                      child: Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: c,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.white.withOpacity(
                                                  _color == c ? .85 : .2),
                                              spreadRadius: _color == c ? 2 : 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ]),
                            const SizedBox(height: 16),
                            Text('酒品图片',
                                style: AppType.sans(
                                    size: 11.5,
                                    weight: FontWeight.w500,
                                    color: Colors.white.withOpacity(.5),
                                    height: 1.0)),
                            const SizedBox(height: 9),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (var i = 0; i < _pickedImages.length; i++)
                                  Stack(children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: _imagePreview(_pickedImages[i]),
                                    ),
                                    Positioned(
                                      right: -4,
                                      top: -4,
                                      child: GestureDetector(
                                          onTap: () => setState(
                                              () => _pickedImages.removeAt(i)),
                                          child: const CircleAvatar(
                                              radius: 10,
                                              child:
                                                  Icon(Icons.close, size: 12))),
                                    ),
                                  ]),
                                GestureDetector(
                                  onTap: _pickImages,
                                  child: Container(
                                      width: 64,
                                      height: 64,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          color: Colors.white.withOpacity(.1),
                                          border: Border.all(
                                              color: Colors.white
                                                  .withOpacity(.22))),
                                      child: const Icon(
                                          Icons.add_photo_alternate_outlined,
                                          color: Colors.white70)),
                                ),
                              ],
                            ),
                          ]),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ---- 配方原料 ----
                  RiseIn(
                    delay: const Duration(milliseconds: 80),
                    child: GlassCard(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('配方原料', style: AppType.eyebrow()),
                                GestureDetector(
                                  onTap: () => setState(
                                      () => _rows.add(_IngredientRow())),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 11, vertical: 6),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(99),
                                      color: Colors.white.withOpacity(.12),
                                      border: Border.all(
                                          color: Colors.white.withOpacity(.28)),
                                    ),
                                    child: Text('+ 添加',
                                        style: AppType.sans(
                                            size: 11.5,
                                            weight: FontWeight.w600,
                                            height: 1.0)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            for (var i = 0; i < _rows.length; i++)
                              Padding(
                                padding: EdgeInsets.only(
                                    bottom: i == _rows.length - 1 ? 0 : 8),
                                child: Row(children: [
                                  Expanded(
                                      flex: 16,
                                      child: _input(_rows[i].name, '原料',
                                          dense: true)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      flex: 10,
                                      child: _input(_rows[i].amount, '用量',
                                          dense: true, mono: true)),
                                  const SizedBox(width: 8),
                                  GlassCircleButton(
                                    icon: PhosphorIcons.minus(),
                                    size: 34,
                                    iconSize: 14,
                                    onTap: () => setState(() {
                                      _rows[i].dispose();
                                      _rows.removeAt(i);
                                      if (_rows.isEmpty) {
                                        _rows = [_IngredientRow()];
                                      }
                                    }),
                                  ),
                                ]),
                              ),
                          ]),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ---- 调制步骤 ----
                  RiseIn(
                    delay: const Duration(milliseconds: 160),
                    child: GlassCard(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('调制步骤 · 每行一步', style: AppType.eyebrow()),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _steps,
                              maxLines: 4,
                              style: AppType.sans(size: 14, height: 1.6),
                              decoration: _decoration('搅拌至冰凉\n滤入古典杯'),
                            ),
                          ]),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ---- 保存按钮 ----
                  PressScale(
                    onTap: _save,
                    scale: .97,
                    child: Container(
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        color: Colors.white.withOpacity(.95),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.4),
                            blurRadius: 36,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Text(_isEdit ? '保存修改' : '加入我的酒单',
                          style: AppType.serifZh(
                              size: 16,
                              color: const Color(0xFF0D0B10),
                              height: 1.0,
                              letterSpacing: .5)),
                    ),
                  ),
                ]),
          ),
        ),
        if (_saving)
          Positioned.fill(
            child: ColoredBox(
              color: const Color(0x990D0B10),
              child: AppLoadingView(themeColor: _color),
            ),
          ),
      ]),
    );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppType.sans(
            size: 14, color: Colors.white.withOpacity(.35), height: 1.4),
        filled: true,
        fillColor: Colors.white.withOpacity(.07),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(.14)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(.3)),
        ),
      );

  Widget _input(TextEditingController c, String hint,
      {bool dense = false, bool mono = false}) {
    return TextField(
      controller: c,
      style: mono
          ? AppType.mono(size: 13.5, weight: FontWeight.w400)
          : AppType.sans(size: dense ? 13.5 : 14, height: 1.2),
      decoration: _decoration(hint).copyWith(
        contentPadding: dense
            ? const EdgeInsets.symmetric(horizontal: 13, vertical: 11)
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(dense ? 14 : 16),
          borderSide: BorderSide(color: Colors.white.withOpacity(.14)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(dense ? 14 : 16),
          borderSide: BorderSide(color: Colors.white.withOpacity(.3)),
        ),
      ),
    );
  }
}
