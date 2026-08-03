import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http_parser/http_parser.dart';

import '../../components/glass.dart';
import '../../components/content_dialog.dart';
import '../../components/app_loading_view.dart';
import '../../components/frosted_page_overlay.dart';
import '../../components/option_wheel_sheet.dart';
import '../../core/theme/app_colors.dart';
import '../../core/network/api_exception.dart';
import '../../core/query/query_cache.dart';
import '../../core/theme/app_effects.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../models/cocktail.dart';
import '../../data/apis/api_providers.dart';
import '../../data/apis/cocktail_api.dart';
import '../../data/apis/upload_api.dart';
import '../../stores/deck_store.dart';
import '../../stores/settings_store.dart';
import '../../stores/user_store.dart';
import '../../stores/my_cocktails_store.dart';
import '../../l10n/l10n.dart';
import '../../l10n/generated/app_localizations.dart';

/// 上传 / 编辑酒单覆盖层 —— 原型 uploading 视图。
/// 保存逻辑与原型 saveForm 一致：中文名必填；英文名默认 House Original；
/// abv 20 / tags [私藏] / 用量留空默认 "适量"。
class UploadView extends ConsumerStatefulWidget {
  const UploadView(
      {super.key, this.editId, this.initialDrink, this.privateByDefault});

  final String? editId;
  final Cocktail? initialDrink;
  final bool? privateByDefault;

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
  static const _maxImageBytes = 15 * 1024 * 1024;
  final _zh = TextEditingController();
  final _en = TextEditingController();
  final _steps = TextEditingController();
  String? _spirit;
  Color _color = AppColors.swatch.first;
  List<_IngredientRow> _rows = [_IngredientRow(), _IngredientRow()];
  final List<XFile> _pickedImages = [];
  bool _imageSelectionInvalid = false;
  bool _saving = false;
  bool _allowPop = false;
  bool _handlingPop = false;
  // 普通入口默认公开；“我的酒单”入口可传入私密默认值。
  late bool _createPrivate;
  late bool _initialCreatePrivate;
  final Map<String, String> _fieldErrors = {};

  Widget _validation(String field) {
    final message = _fieldErrors[field];
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 7, left: 2),
      child: Text(message,
          style: AppType.sans(size: 12, color: const Color(0xFFFF8A8A))),
    );
  }

  bool _validateForm({bool forSubmission = false}) {
    final l10n = context.l10n;
    final errors = <String, String>{};
    if (_zh.text.trim().isEmpty && _en.text.trim().isEmpty) {
      errors['name'] = l10n.validationNameRequired;
    }
    if (_spirit == null || _spirit!.trim().isEmpty) {
      errors['spirit'] = l10n.validationSpiritRequired;
    }
    if (_imageSelectionInvalid) {
      errors['images'] = l10n.selectImagesAgain;
    }
    final hasImages = _pickedImages
            .any((image) => image.path.trim().isNotEmpty) ||
        (widget.initialDrink?.images.any((image) => image.trim().isNotEmpty) ??
            false);
    if (forSubmission && !hasImages) {
      errors['images'] = l10n.validationImagesRequired;
    }
    if (forSubmission && !_rows.any((row) => row.name.text.trim().isNotEmpty)) {
      errors['recipe'] = l10n.validationRecipeRequired;
    }
    if (forSubmission && _steps.text.trim().isEmpty) {
      errors['steps'] = l10n.validationStepsRequired;
    }
    setState(() {
      _fieldErrors
        ..clear()
        ..addAll(errors);
    });
    return errors.isEmpty;
  }

  late final DeckController _deckController;

  bool get _isEdit => widget.editId != null;

  late final String _initialEditSignature;

  String get _editSignature => [
        _zh.text,
        _en.text,
        _steps.text,
        _spirit ?? '',
        _color.toARGB32(),
        _createPrivate,
        for (final row in _rows) '${row.name.text}\u0000${row.amount.text}',
        for (final image in _pickedImages) image.path,
      ].join('\u0001');

  bool get _hasUnsavedChanges {
    if (_isEdit) return _editSignature != _initialEditSignature;
    return _zh.text.trim().isNotEmpty ||
        _en.text.trim().isNotEmpty ||
        _steps.text.trim().isNotEmpty ||
        _pickedImages.isNotEmpty ||
        _imageSelectionInvalid ||
        _color != AppColors.swatch.first ||
        _createPrivate != _initialCreatePrivate ||
        _rows.any((row) =>
            row.name.text.trim().isNotEmpty ||
            row.amount.text.trim().isNotEmpty);
  }

  void _endSaving() {
    if (mounted && _saving) setState(() => _saving = false);
  }

  @override
  void initState() {
    super.initState();
    _createPrivate = widget.privateByDefault ?? false;
    _deckController = ref.read(deckControllerProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _deckController.pause();
      if (!ref.read(userProvider).isLoggedIn) {
        ref.read(toastProvider.notifier).show(context.l10n.loginToCreate);
        context.go('/login');
      }
    });
    // 编辑模式：回填表单（原型 m.edit）
    if (_isEdit) {
      final m = <Cocktail>[
        if (widget.initialDrink?.id == widget.editId) widget.initialDrink!,
        ...ref.read(appDataProvider).mine.where((x) => x.id == widget.editId),
      ];
      if (m.isNotEmpty) {
        final d = m.first;
        _zh.text = d.zh;
        _en.text = d.en;
        _spirit = d.spirit;
        _createPrivate = d.isPrivate;
        _color = d.themeColor;
        final unit = ref.read(appDataProvider).unit;
        _rows = d.recipe
            .map((r) => _IngredientRow(
                n: r.n, t: r.ml == null ? '' : _amountFromMl(r.ml!, unit)))
            .toList();
        if (_rows.isEmpty) _rows = [_IngredientRow()];
        _steps.text = d.steps.join('\n');
      }
    }
    _initialEditSignature = _editSignature;
    _initialCreatePrivate = _createPrivate;
  }

  Future<bool> _confirmDiscard() async {
    if (!_hasUnsavedChanges) return true;
    final discard = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: Text(context.l10n.discardChangesTitle),
        message: Text(context.l10n.discardChangesBody),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(sheetContext, true),
            child: Text(context.l10n.discard),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheetContext, false),
          child: Text(context.l10n.keepEditing),
        ),
      ),
    );
    return discard ?? false;
  }

  Future<void> _requestClose() async {
    if (_saving || _handlingPop) return;
    _handlingPop = true;
    if (!_isEdit && _hasUnsavedChanges) {
      final saveDraft = await showCupertinoModalPopup<bool>(
        context: context,
        builder: (sheetContext) => CupertinoActionSheet(
          title: Text(context.l10n.saveDraftPromptTitle),
          message: Text(context.l10n.saveDraftPromptBody),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(sheetContext, true),
              child: Text(context.l10n.saveDraftAndExit),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(sheetContext, false),
              child: Text(context.l10n.leaveWithoutSaving),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(sheetContext),
            child: Text(context.l10n.keepEditing),
          ),
        ),
      );
      _handlingPop = false;
      if (!mounted || saveDraft == null) return;
      if (saveDraft) {
        await _save();
        return;
      }
      setState(() => _allowPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
      return;
    }
    final close = await _confirmDiscard();
    _handlingPop = false;
    if (!close || !mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.pop();
    });
  }

  @override
  void dispose() {
    // 关闭上传覆盖页时延后一帧恢复卡组，避免路由重建期触发 notifyListeners。
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _deckController.resume());
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
    var invalid = 0;
    for (final file in files) {
      if (await file.length() > _maxImageBytes) {
        oversized++;
        continue;
      }
      final normalized = await _compressToJpeg(file);
      if (normalized == null) {
        invalid++;
      } else if (await normalized.length() > _maxImageBytes) {
        oversized++;
      } else {
        accepted.add(normalized);
      }
    }
    if (!mounted) return;
    if (oversized > 0 || invalid > 0) {
      setState(() => _imageSelectionInvalid = true);
      ref.read(toastProvider.notifier).show(invalid > 0
          ? context.l10n.uploadInvalidImage
          : context.l10n.imageTooLarge(oversized));
      return;
    }
    setState(() {
      _imageSelectionInvalid = false;
      _pickedImages.addAll(accepted);
    });
  }

  /// 统一转 JPEG：最长边 2048px、质量 82，兼容 iPhone HEIC 与后端格式限制。
  Future<XFile?> _compressToJpeg(XFile source) async {
    // Web 没有 path_provider 的临时目录实现；浏览器已在选择阶段提供可上传文件，
    // 仍由下方 15MB 校验与服务端限制兜底。
    if (kIsWeb) {
      final bytes = await source.readAsBytes();
      return _mediaType(bytes) == null ? null : source;
    }
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

  Widget _imagePreview(XFile image,
      {double? width = 64, double? height = 64, BoxFit fit = BoxFit.cover}) {
    if (!kIsWeb) {
      return Image.file(File(image.path),
          width: width, height: height, fit: fit);
    }
    return FutureBuilder(
      future: image.readAsBytes(),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) return SizedBox(width: width, height: height);
        return Image.memory(bytes, width: width, height: height, fit: fit);
      },
    );
  }

  Future<MultipartFile> _multipartFile(XFile file) async {
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      final mediaType = _mediaType(bytes);
      if (mediaType == null) throw const FormatException('Invalid image');
      return MultipartFile.fromBytes(
        bytes,
        filename: file.name,
        contentType: mediaType,
      );
    }
    return MultipartFile.fromFile(file.path,
        filename: file.name, contentType: MediaType('image', 'jpeg'));
  }

  MediaType? _mediaType(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return MediaType('image', 'jpeg');
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return MediaType('image', 'png');
    }
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      return MediaType('image', 'webp');
    }
    return null;
  }

  static String _amountFromMl(num ml, String unit) {
    if (unit == 'ml') {
      return ml == ml.roundToDouble() ? ml.toStringAsFixed(0) : '$ml';
    }
    final oz = (ml / 29.5735 * 4).round() / 4;
    return oz == oz.roundToDouble()
        ? oz.toStringAsFixed(0)
        : oz.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  }

  void _showImage(XFile image) {
    showContentDialog<void>(
      context: context,
      title: context.l10n.imagePreview,
      content: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _imagePreview(image,
            width: double.infinity,
            height: MediaQuery.sizeOf(context).height * .62,
            fit: BoxFit.contain),
      ),
    );
  }

  Future<List<String>> _uploadCocktailImages() async {
    final urls = <String>[];
    for (final file in _pickedImages) {
      final url = await ref.read(uploadApiProvider).uploadImage(
            await _multipartFile(file),
            purpose: UploadPurpose.cocktail,
          );
      if (url.trim().isEmpty) throw const FormatException('Empty image URL');
      urls.add(url);
    }
    return urls;
  }

  String _uploadErrorMessage(ApiException error, AppLocalizations l10n) {
    switch (error.code) {
      case 400:
        return l10n.uploadInvalidImage;
      case 401:
        return l10n.sessionExpired;
      case 413:
        return l10n.uploadImageTooLarge;
      case 429:
        return l10n.uploadTooFrequent;
      default:
        return l10n.uploadFailed;
    }
  }

  Future<bool> _save({
    bool closeAfterSave = true,
    bool submitAfterSave = false,
  }) async {
    if (_saving) return false;
    final l10n = context.l10n;
    final englishLocale = Localizations.localeOf(context).languageCode == 'en';
    if (!_validateForm(forSubmission: submitAfterSave)) return false;
    if (submitAfterSave && _createPrivate) {
      setState(() => _fieldErrors['privacy'] = l10n.validationPrivateSubmit);
      return false;
    }
    final primaryName = (englishLocale ? _en.text : _zh.text).trim();
    final chineseName = _zh.text.trim().isEmpty ? primaryName : _zh.text.trim();
    final englishName = _en.text.trim().isEmpty
        ? (englishLocale ? primaryName : 'House Original')
        : _en.text.trim();
    CocktailCategory? category;
    for (final candidate in ref.read(cocktailCategoriesProvider).valueOrNull ??
        const <CocktailCategory>[]) {
      if (candidate.code == _spirit) category = candidate;
    }
    if (category == null) return false;
    setState(() => _saving = true);
    var uploadingImages = false;
    try {
      final rows = _rows.where((r) => r.name.text.trim().isNotEmpty).map((r) {
        final amount = double.tryParse(r.amount.text.trim());
        if (amount == null) {
          return RecipeItem(n: r.name.text.trim(), t: l10n.suitableAmount);
        }
        final unit = ref.read(appDataProvider).unit;
        final milliliters = unit == 'oz' ? amount * 29.5735 : amount;
        return RecipeItem(n: r.name.text.trim(), ml: milliliters.round());
      }).toList();
      final hexColor =
          '#${_color.value.toRadixString(16).substring(2).toUpperCase()}';
      // 两阶段提交：逐张上传且全部成功后，才允许创建/更新酒单。
      uploadingImages = true;
      final uploadedImages = await _uploadCocktailImages();
      final images = _isEdit
          ? <String>{
              ...?widget.initialDrink?.images,
              ...uploadedImages,
            }.toList(growable: false)
          : uploadedImages;
      uploadingImages = false;
      if (!mounted) return false;
      final item = Cocktail(
        id: widget.editId ?? 'my-${DateTime.now().millisecondsSinceEpoch}',
        zh: chineseName,
        en: englishName,
        spirit: category.code,
        base: category.name,
        abv: 20,
        color: hexColor,
        images: images,
        tags: _createPrivate ? [l10n.privateTag] : const [],
        glass: l10n.yourPreferredGlass,
        garnish: l10n.freeGarnish,
        flavor: l10n.personalFlavor,
        story: l10n.personalStory,
        recipe: rows,
        steps:
            _steps.text.split('\n').where((s) => s.trim().isNotEmpty).toList(),
      );
      final request = CocktailUpsertRequest(
        zh: item.zh,
        en: item.en,
        spirit: category.code,
        abv: _isEdit ? null : item.abv,
        color: item.color,
        images: item.images,
        tags: _isEdit ? null : item.tags,
        glass: _isEdit ? null : item.glass,
        garnish: _isEdit ? null : item.garnish,
        flavor: _isEdit ? null : item.flavor,
        story: _isEdit ? null : item.story,
        recipe: item.recipe,
        steps: item.steps,
        isPrivate: widget.initialDrink?.status == CocktailStatus.published
            ? null
            : _createPrivate,
      );
      Cocktail saved;
      if (_isEdit) {
        saved =
            await ref.read(cocktailApiProvider).update(widget.editId!, request);
      } else {
        saved = await ref.read(cocktailApiProvider).create(request);
      }
      if (submitAfterSave) {
        await ref.read(cocktailApiProvider).submit(saved.id);
      }
      ref.read(queryClientProvider).invalidateQueries(myCocktailsQueryPrefix);
      ref.invalidate(myCocktailsProvider);
      ref.read(toastProvider.notifier).show(submitAfterSave
          ? l10n.cocktailSubmitted
          : (_isEdit
              ? l10n.updated
              : (_createPrivate
                  ? l10n.privateCocktailCreated
                  : l10n.publicDraftCreated)));
      if (closeAfterSave && mounted) context.pop();
      return true;
    } on ApiException catch (error) {
      if (mounted) {
        _endSaving();
        ref.read(toastProvider.notifier).show(
            uploadingImages ? _uploadErrorMessage(error, l10n) : error.message);
        if (uploadingImages && error.code == 401) context.go('/login');
      }
      return false;
    } catch (_) {
      if (mounted) {
        _endSaving();
        ref.read(toastProvider.notifier).show(l10n.uploadFailed);
      }
      return false;
    } finally {
      _endSaving();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final loggedIn = ref.watch(userProvider).isLoggedIn;
    final unit = ref.watch(appDataProvider.select((data) => data.unit));
    final categoryState = ref.watch(cocktailCategoriesProvider);
    final categories = categoryState.valueOrNull ?? const <CocktailCategory>[];
    CocktailCategory? selectedCategory;
    for (final category in categories) {
      if (category.code == _spirit) selectedCategory = category;
    }
    final languageCode = Localizations.localeOf(context).languageCode;
    final englishLocale = languageCode == 'en';
    if (_spirit == null && categories.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _spirit == null) {
          setState(() => _spirit = categories.first.code);
        }
      });
    }

    return PopScope(
      canPop: _allowPop || !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _requestClose();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Stack(children: [
              FrostedPageOverlay(
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
                                  Text(context.l10n.newRecipe,
                                      style: AppType.eyebrow(
                                          size: 11,
                                          tracking: .18,
                                          color:
                                              Colors.white.withOpacity(.42))),
                                  const SizedBox(height: 7),
                                  Text(context.l10n.uploadCocktail,
                                      style: AppType.serifZh(
                                          size: 26, height: 1.2)),
                                ]),
                            GlassCircleButton(
                              icon: PhosphorIcons.x(PhosphorIconsStyle.bold),
                              appleSystemImageName: 'xmark',
                              size: 38,
                              iconSize: 15,
                              iconColor: Colors.white,
                              semanticLabel: context.l10n.close,
                              onTap: _requestClose,
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
                                  _itemTitle(context.l10n.nameLabel),
                                  const SizedBox(height: 10),
                                  _input(
                                    englishLocale ? _en : _zh,
                                    englishLocale
                                        ? context.l10n.englishNameHint
                                        : context.l10n.chineseNameHint,
                                  ),
                                  _validation('name'),
                                  if (!englishLocale) ...[
                                    const SizedBox(height: 16),
                                    _itemTitle(context.l10n.englishNameLabel),
                                    const SizedBox(height: 10),
                                    _input(
                                      _en,
                                      context.l10n.englishNameHint,
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  _itemTitle(context.l10n.baseSpirit),
                                  const SizedBox(height: 10),
                                  OptionWheelButton(
                                    controlKey: const ValueKey(
                                      'base_spirit_select',
                                    ),
                                    label: selectedCategory?.labelFor(
                                          languageCode,
                                        ) ??
                                        context.l10n.baseSpirit,
                                    semanticLabel: context.l10n.baseSpirit,
                                    onPressed: categories.isEmpty
                                        ? null
                                        : () => _showSpiritWheel(
                                              context,
                                              categories,
                                              languageCode,
                                            ),
                                  ),
                                  _validation('spirit'),
                                  if (categoryState.isLoading)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child:
                                          LinearProgressIndicator(minHeight: 2),
                                    ),
                                  const SizedBox(height: 16),
                                  _itemTitle(context.l10n.themeColor),
                                  const SizedBox(height: 10),
                                  Row(children: [
                                    for (final c in AppColors.swatch)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 10),
                                        child: GestureDetector(
                                          onTap: () =>
                                              setState(() => _color = c),
                                          child: AnimatedScale(
                                            scale: _color == c ? 1.15 : 1,
                                            duration: const Duration(
                                                milliseconds: 300),
                                            curve: AppMotion.spring,
                                            child: Container(
                                              width: 34,
                                              height: 34,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: c,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.white
                                                        .withOpacity(_color == c
                                                            ? .85
                                                            : .2),
                                                    spreadRadius:
                                                        _color == c ? 2 : 1,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ]),
                                  const SizedBox(height: 16),
                                  _itemTitle(context.l10n.cocktailImages),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (var i = 0;
                                          i < _pickedImages.length;
                                          i++)
                                        SizedBox(
                                          width: 70,
                                          height: 70,
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              Positioned.fill(
                                                child: GestureDetector(
                                                  onTap: () => _showImage(
                                                      _pickedImages[i]),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    child: _imagePreview(
                                                        _pickedImages[i],
                                                        width: 70,
                                                        height: 70),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                right: -6,
                                                top: -6,
                                                child: GestureDetector(
                                                  onTap: () => setState(() =>
                                                      _pickedImages
                                                          .removeAt(i)),
                                                  child: SizedBox.square(
                                                    dimension: 44,
                                                    child: Center(
                                                      child: Container(
                                                        width: 24,
                                                        height: 24,
                                                        decoration:
                                                            BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: const Color(
                                                              0xFF232027),
                                                          border: Border.all(
                                                            color: Colors.white
                                                                .withOpacity(
                                                                    .7),
                                                          ),
                                                        ),
                                                        child: const Icon(
                                                            Icons.close,
                                                            size: 14,
                                                            color:
                                                                Colors.white),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      GestureDetector(
                                        onTap: _pickImages,
                                        child: Container(
                                            width: 64,
                                            height: 64,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                color: Colors.white
                                                    .withOpacity(.1),
                                                border: Border.all(
                                                    color: Colors.white
                                                        .withOpacity(.22))),
                                            child: const Icon(
                                                Icons
                                                    .add_photo_alternate_outlined,
                                                color: Colors.white70)),
                                      ),
                                    ],
                                  ),
                                  _validation('images'),
                                  if (loggedIn) ...[
                                    const SizedBox(height: 18),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 13, vertical: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        color: Colors.white.withOpacity(.06),
                                        border: Border.all(
                                            color:
                                                Colors.white.withOpacity(.12)),
                                      ),
                                      child: Row(children: [
                                        Icon(PhosphorIcons.lockKey(),
                                            size: 16,
                                            color:
                                                Colors.white.withOpacity(.72)),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    context.l10n
                                                        .createPrivateCocktail,
                                                    style: AppType.sans(
                                                        size: 13.5,
                                                        weight:
                                                            FontWeight.w600)),
                                                const SizedBox(height: 2),
                                                Text(
                                                    _createPrivate
                                                        ? context.l10n
                                                            .privateCocktailDescription
                                                        : context.l10n
                                                            .publicCocktailDescription,
                                                    style: AppType.sans(
                                                        size: 11.5,
                                                        color: Colors.white
                                                            .withOpacity(.45))),
                                              ]),
                                        ),
                                        Switch.adaptive(
                                          value: _createPrivate,
                                          activeThumbColor:
                                              AppColors.systemAccent,
                                          onChanged: widget
                                                      .initialDrink?.status ==
                                                  CocktailStatus.published
                                              ? null
                                              : (value) => setState(
                                                  () => _createPrivate = value),
                                        ),
                                      ]),
                                    ),
                                    _validation('privacy'),
                                  ],
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _itemTitle(context.l10n.ingredients),
                                      GestureDetector(
                                        onTap: () => setState(
                                            () => _rows.add(_IngredientRow())),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 11, vertical: 6),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(99),
                                            color:
                                                Colors.white.withOpacity(.12),
                                            border: Border.all(
                                                color: Colors.white
                                                    .withOpacity(.28)),
                                          ),
                                          child: Text('+ ${context.l10n.add}',
                                              style: AppType.sans(
                                                  size: 11.5,
                                                  weight: FontWeight.w600,
                                                  height: 1.0)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  for (var i = 0; i < _rows.length; i++)
                                    Padding(
                                      padding: EdgeInsets.only(
                                          bottom:
                                              i == _rows.length - 1 ? 0 : 8),
                                      child: Row(children: [
                                        Expanded(
                                            flex: 16,
                                            child: _input(_rows[i].name,
                                                context.l10n.ingredient,
                                                dense: true)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                            flex: 10,
                                            child: _input(_rows[i].amount,
                                                context.l10n.amount,
                                                dense: true,
                                                mono: true,
                                                suffix: unit)),
                                        const SizedBox(width: 8),
                                        GlassCircleButton(
                                          icon: PhosphorIcons.minus(),
                                          appleSystemImageName: 'minus',
                                          size: 34,
                                          iconSize: 14,
                                          semanticLabel:
                                              context.l10n.removeIngredient,
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
                                  _validation('recipe'),
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
                                  _itemTitle(context.l10n.stepsPerLine),
                                  const SizedBox(height: 10),
                                  _input(
                                    _steps,
                                    context.l10n.stepsHint,
                                    maxLines: 4,
                                    keyboardType: TextInputType.multiline,
                                    textInputAction: TextInputAction.newline,
                                  ),
                                  _validation('steps'),
                                ]),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // ---- 提交 / 草稿按钮 ----
                        SizedBox(
                          width: double.infinity,
                          child: Column(
                            children: [
                              GlassActionButton(
                                label: context.l10n.createCocktail,
                                width: double.infinity,
                                fontSize: 15,
                                // 使用普通白色 glass，避免系统 prominentGlass 的蓝色强调色。
                                prominent: false,
                                onTap: _saving
                                    ? null
                                    : () => _save(submitAfterSave: true),
                              ),
                              const SizedBox(height: 10),
                              GlassActionButton(
                                label: _isEdit
                                    ? context.l10n.saveChanges
                                    : context.l10n.saveDraft,
                                width: double.infinity,
                                fontSize: 13.5,
                                backgroundColor: const Color(0xFFDDE2E8),
                                onTap: _saving ? null : _save,
                              ),
                            ],
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
            ])),
      ),
    );
  }

  Future<void> _showSpiritWheel(
    BuildContext context,
    List<CocktailCategory> categories,
    String languageCode,
  ) async {
    if (categories.isEmpty) return;
    final l10n = context.l10n;
    final selected = await showOptionWheel<String>(
      context: context,
      title: l10n.baseSpirit,
      cancelLabel: l10n.cancel,
      doneLabel: l10n.done,
      selectedValue: _spirit ?? categories.first.code,
      options: [
        for (final category in categories)
          OptionWheelItem(
            value: category.code,
            label: category.labelFor(languageCode),
          ),
      ],
    );
    if (!mounted || selected == null || selected == _spirit) return;
    setState(() => _spirit = selected);
  }

  Widget _itemTitle(String title) => Text(
        title,
        style: AppType.sans(
          size: 13.5,
          weight: FontWeight.w600,
          color: Colors.white,
          height: 1.2,
        ),
      );

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppType.sans(
            size: 14, color: Colors.white.withOpacity(.35), height: 1.4),
        filled: false,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      );

  Widget _input(TextEditingController c, String hint,
      {bool dense = false,
      bool mono = false,
      String? suffix,
      int maxLines = 1,
      TextInputType? keyboardType,
      TextInputAction? textInputAction}) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Focus(
      child: Builder(
        builder: (fieldContext) {
          final focused = Focus.of(fieldContext).hasFocus;
          return AnimatedContainer(
            duration: reduceMotion ? Duration.zero : AppMotion.fast,
            curve: AppMotion.standard,
            constraints: const BoxConstraints(minHeight: 44),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: focused ? .18 : .15),
                  Colors.white.withValues(alpha: focused ? .09 : .07),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: focused ? .38 : .18),
              ),
            ),
            child: TextField(
              controller: c,
              maxLines: maxLines,
              keyboardType: keyboardType ??
                  (suffix == null
                      ? TextInputType.text
                      : const TextInputType.numberWithOptions(decimal: true)),
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              textInputAction: textInputAction ??
                  (suffix == null
                      ? TextInputAction.next
                      : TextInputAction.done),
              inputFormatters: suffix == null
                  ? null
                  : [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
              style: mono
                  ? AppType.mono(size: 13.5, weight: FontWeight.w400)
                  : AppType.sans(
                      size: dense ? 13.5 : 14,
                      height: maxLines > 1 ? 1.6 : 1.2,
                    ),
              decoration: _decoration(hint).copyWith(
                suffixText: suffix,
                contentPadding: dense
                    ? const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
