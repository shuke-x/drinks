// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '今晚喝什么';

  @override
  String get newRecipe => 'NEW RECIPE';

  @override
  String get uploadCocktail => '新建酒单';

  @override
  String get nameLabel => 'Cocktail name';

  @override
  String get englishNameLabel => 'English name';

  @override
  String get chineseNameHint => '中文名，如 山楂古典';

  @override
  String get englishNameHint => '英文名，如 Hawthorn Old Fashioned';

  @override
  String get baseSpirit => '基酒';

  @override
  String get themeColor => '主题色';

  @override
  String get cocktailImages => '酒品图片';

  @override
  String get createPrivateCocktail => '创建为私人酒单';

  @override
  String get privateCocktailDescription => '将归属到当前账号，可在私人酒单中管理。';

  @override
  String get publicCocktailDescription => '保存为公开草稿，完成后可提交审核。';

  @override
  String get ingredients => '配方原料';

  @override
  String get add => '添加';

  @override
  String get ingredient => '原料';

  @override
  String get amount => '用量';

  @override
  String get stepsPerLine => '调制步骤 · 每行一步';

  @override
  String get stepsHint => '搅拌至冰凉\n滤入古典杯';

  @override
  String get saveChanges => '保存修改';

  @override
  String get addToMyCocktails => '加入我的酒单';

  @override
  String get createCocktail => '创建酒单';

  @override
  String get enterChineseName => '请先填写酒名';

  @override
  String get validationNameRequired => '请输入酒名';

  @override
  String get validationSpiritRequired => '请选择基酒';

  @override
  String get validationRecipeRequired => '请至少填写一种原料';

  @override
  String get validationStepsRequired => '请填写调制步骤';

  @override
  String get validationImagesRequired => '请至少上传一张酒单图片';

  @override
  String get validationPrivateSubmit => '私密酒单不能提交审核';

  @override
  String get saveDraftPromptTitle => '保存草稿？';

  @override
  String get saveDraftPromptBody => '当前内容会保存到草稿，之后可以继续编辑并提交审核。';

  @override
  String get saveDraft => '保存草稿';

  @override
  String get saveDraftAndExit => '保存草稿并退出';

  @override
  String get leaveWithoutSaving => '不保存并退出';

  @override
  String imageTooLarge(Object count) {
    return '$count 张图片超过 15MB，已跳过';
  }

  @override
  String get selectImagesAgain => '图片未通过校验，请重新选择后再提交';

  @override
  String get uploadInvalidImage => '图片格式或真实内容不正确';

  @override
  String get uploadImageTooLarge => '图片过大';

  @override
  String get uploadTooFrequent => '上传过于频繁，请稍后重试';

  @override
  String get updated => '已更新';

  @override
  String get privateCocktailCreated => '已创建私人酒单';

  @override
  String get publicDraftCreated => '公开酒单草稿已保存';

  @override
  String get addedToMyCocktails => '已加入我的酒单';

  @override
  String get uploadFailed => '上传失败，请稍后重试';

  @override
  String get imagePreview => '图片预览';

  @override
  String get close => '关闭';

  @override
  String get discardChangesTitle => '放弃修改？';

  @override
  String get discardChangesBody => '尚未保存的酒单内容将会丢失。';

  @override
  String get keepEditing => '继续编辑';

  @override
  String get discard => '放弃';

  @override
  String get todayDrink => '今天喝什么';

  @override
  String get loginToCreate => '登录后才能新建酒单';

  @override
  String get tapToLogin => '点击登录';

  @override
  String get editProfile => '点击修改资料';

  @override
  String get loginManageCocktails => '登录后管理你的酒单';

  @override
  String get myFavorites => '我的收藏';

  @override
  String favoriteCount(Object count) {
    return '已收藏 $count 杯酒单';
  }

  @override
  String get loginToFavoriteSubtitle => '登录后可收藏喜欢的酒单';

  @override
  String get unitsAndCalculation => '单位与计算';

  @override
  String get milliliterDescription => '当前以毫升显示配方用量';

  @override
  String get ounceDescription => '当前以盎司显示配方用量';

  @override
  String get language => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageEnglish => 'English';

  @override
  String languageDescription(Object language) {
    return '当前：$language';
  }

  @override
  String get loginToFavorite => '登录后即可收藏';

  @override
  String get favoriteAdded => '已加入收藏';

  @override
  String get favoriteRemoved => '已取消收藏';

  @override
  String get favoriteSyncFailed => '收藏同步失败，请稍后重试';

  @override
  String get sessionExpired => '登录已过期，请重新登录';

  @override
  String get categoryLoadFailed => '基酒分类加载失败，请稍后重试';

  @override
  String get suitableAmount => '适量';

  @override
  String get home => '发现';

  @override
  String get all => '全部';

  @override
  String get next => '灵感';

  @override
  String get records => '记录';

  @override
  String get recipes => '配方';

  @override
  String get recommend => '风味';

  @override
  String get cocktails => '酒柜';

  @override
  String get user => '我的';

  @override
  String get search => '搜索';

  @override
  String get searchCocktails => '搜索酒单';

  @override
  String get searchCocktailsHint => '搜索酒名、基酒、标签或原料';

  @override
  String get searchNoResults => '没有找到相关酒单';

  @override
  String get searchNoResultsHint => '换一个酒名、基酒或原料试试。';

  @override
  String get emptyCocktails => '这里还没有酒单';

  @override
  String get cocktailsPreparing => '酒单准备中，稍后再来看看。';

  @override
  String get tryAnotherCategory => '换个分类，看看其他风味。';

  @override
  String get noCocktailOptions => '还没有可选的酒单';

  @override
  String get optionsPreparing => '等酒单准备好后，再来决定今晚喝什么。';

  @override
  String get noFavorites => '还没有收藏';

  @override
  String get favoriteEmptyHint => '在酒单详情页点亮心形图标吧。';

  @override
  String get privateCocktails => '我创建的酒单';

  @override
  String privateCocktailSubtitle(Object name) {
    return '$name 的草稿、私藏与公开酒单';
  }

  @override
  String get privateCocktailEmpty => '这里将收纳你创建的酒单';

  @override
  String get privateCocktailEmptyHint => '创建私人酒单，或提交一杯作品公开审核。';

  @override
  String get designPrivateCocktail => 'Design yours';

  @override
  String get cocktailStatusAll => '全部';

  @override
  String get cocktailStatusDraft => '草稿';

  @override
  String get cocktailStatusPending => '审核中';

  @override
  String get cocktailStatusRejected => '需修改';

  @override
  String get cocktailStatusPublished => '已公开';

  @override
  String get cocktailStatusOffline => '已下架';

  @override
  String get cocktailStatusPrivate => '私人';

  @override
  String get submitForReview => '提交审核';

  @override
  String get withdrawReview => '撤回审核';

  @override
  String get editCocktail => '编辑酒单';

  @override
  String get deleteCocktail => '删除酒单';

  @override
  String get deleteDraft => '删除草稿';

  @override
  String get deleteDraftTitle => '删除这份草稿？';

  @override
  String get deleteDraftBody => '删除后无法恢复。';

  @override
  String get deleteCocktailTitle => '删除这杯酒单？';

  @override
  String get deleteCocktailBody => '删除后无法恢复。';

  @override
  String get cocktailSubmitted => '已提交审核';

  @override
  String get cocktailWithdrawn => '已撤回审核';

  @override
  String get cocktailDeleted => '酒单已删除';

  @override
  String get cocktailActionFailed => '操作失败，请稍后重试';

  @override
  String reviewReason(Object reason) {
    return '原因：$reason';
  }

  @override
  String ingredientCount(Object base, Object count) {
    return '$base · $count 种原料';
  }

  @override
  String recipeUnit(Object unit) {
    return '配方 · $unit';
  }

  @override
  String get milliliters => '毫升';

  @override
  String get ounces => '盎司';

  @override
  String get method => '调制步骤';

  @override
  String get flavorStory => '风味故事';

  @override
  String get flavorImpression => '风味印象';

  @override
  String get tonightThisOne => '今晚就它了';

  @override
  String get viewRecipe => '查看配方';

  @override
  String get drawAgain => '再抽一次';

  @override
  String get validEmailRequired => '请输入有效邮箱';

  @override
  String get passwordSixCharacters => '密码至少 6 位';

  @override
  String get nicknameRequired => '请填写昵称';

  @override
  String get passwordPolicy => '密码至少 8 位，需含大小写字母、数字和标点';

  @override
  String get registerWelcome => '注册成功，欢迎';

  @override
  String welcomeBack(Object name) {
    return '欢迎回来，$name';
  }

  @override
  String get authFailed => '认证失败，请稍后重试';

  @override
  String get authHero => '今晚，喝点好的。';

  @override
  String get authSubtitle => '留住让你想再喝一杯的味道';

  @override
  String get nickname => '昵称';

  @override
  String get emailAddress => '邮箱地址';

  @override
  String get password => '密码';

  @override
  String get showPassword => '显示密码';

  @override
  String get hidePassword => '隐藏密码';

  @override
  String get startCreating => '开始我的私人创作';

  @override
  String get continueTonight => '继续探索今晚';

  @override
  String get notLoginNow => '暂时不想登录？';

  @override
  String get browseAsGuest => '先随便看看';

  @override
  String get nicknameCannotBeEmpty => '昵称不能为空';

  @override
  String get profileSynced => '资料已同步';

  @override
  String get saveFailed => '保存失败，请稍后重试';

  @override
  String get deleteAccountTitle => '永久删除账户？';

  @override
  String get deleteAccountBody =>
      '你的账户、收藏、私人酒单和相关图片将永久删除。已公开发布的酒单会匿名保留，并显示为“该账户已注销”。此操作无法撤销。';

  @override
  String get cancel => '取消';

  @override
  String get done => '完成';

  @override
  String get currentSelection => '当前选择';

  @override
  String get deletePermanently => '永久删除';

  @override
  String get accountDeleted => '账户已删除';

  @override
  String get deleteFailed => '删除失败，请稍后重试';

  @override
  String get profile => '个人资料';

  @override
  String get startRecordingTaste => '开始记录你的口味';

  @override
  String get loginStart => '登录 / 开始使用';

  @override
  String get enterYourName => '输入你的名字';

  @override
  String get processing => '处理中…';

  @override
  String get saveProfile => '保存资料';

  @override
  String get logout => '退出登录';

  @override
  String get deleteAccount => '删除账户';

  @override
  String get unitSettingsSubtitle => '所有配方用量会按你的偏好即时换算。';

  @override
  String get measurementUnit => '计量单位';

  @override
  String get milliliterMode => '毫升模式：配方将以 ml 显示。';

  @override
  String get ounceMode => '盎司模式：数值按 1/4 oz 取整。';

  @override
  String get glassware => '杯具';

  @override
  String get garnish => '装饰';

  @override
  String get loginBenefits => '登录后可以修改头像、收藏酒单，并使用私人酒单空间。';

  @override
  String get login => '登录';

  @override
  String get register => '注册';

  @override
  String get swipeHint => '左右滑动浏览 · 点击卡片查看配方';

  @override
  String get featuredToday => '今日推荐';

  @override
  String resultFlavor(Object base, Object flavor) {
    return '$flavor 今晚，就让$base带路。';
  }

  @override
  String get privateTag => '私藏';

  @override
  String get yourPreferredGlass => '依你所好';

  @override
  String get freeGarnish => '自由发挥';

  @override
  String get personalFlavor => '来自你自己的酒单。';

  @override
  String get personalStory => '这一杯由你定义。';

  @override
  String get languageSyncFailed => '语言偏好同步失败，请稍后重试';

  @override
  String get loadFailed => '加载失败';

  @override
  String get loadFailedDescription => '网络请求失败或超时，请稍后重试。';

  @override
  String get retry => '重新加载';

  @override
  String get cocktailNotFound => '没有找到这杯酒单';

  @override
  String get addToFavorites => '添加到收藏';

  @override
  String get removeFromFavorites => '从收藏中移除';

  @override
  String get removeIngredient => '移除配料';

  @override
  String get photoAccessDenied => '无法访问照片，请在系统设置中允许照片访问后重试。';

  @override
  String get photoReadFailed => '无法读取照片，请重新选择。';

  @override
  String get privacyAndUse => '隐私与使用说明';

  @override
  String get privacyAndUseSubtitle => '数据使用、年龄要求与账户管理';

  @override
  String get privacyDataTitle => '我们处理的数据';

  @override
  String get privacyDataBody =>
      '账户功能使用邮箱、昵称和账户标识。你上传的头像、配方、收藏和品饮记录会发送至服务端，用于保存和同步。记录可包含照片、地点、价格和笔记。搜索词会发送至服务端以获取结果。';

  @override
  String get privacyPhotosTitle => '照片选择';

  @override
  String get privacyPhotosBody =>
      '仅在你主动选择照片时打开系统相册，用于头像、酒单或品饮记录。取消选择不会清除已填写的内容。';

  @override
  String get privacyDiagnosticsTitle => '错误诊断';

  @override
  String get privacyDiagnosticsBody =>
      '应用错误诊断仅发送错误类别、代码位置生成的分组标识和运行平台，不发送令牌、邮箱、笔记、照片或原始异常内容。';

  @override
  String get privacyAccountTitle => '账户与内容';

  @override
  String get privacyAccountBody =>
      '可在个人资料页永久删除账户。公开发布的配方可能以匿名作者继续保留；删除前请阅读确认说明。请勿在公开内容中加入私人信息。';

  @override
  String get responsibleUseTitle => '年龄与理性饮酒';

  @override
  String get responsibleUseBody =>
      '本应用仅面向年满 18 岁的用户。如所在地的法定饮酒年龄更高，请遵守当地要求。请理性饮酒，不要酒后驾驶。配方仅供参考。';

  @override
  String get privacyPendingTitle => '客服与举报';

  @override
  String get privacyPendingBody =>
      '客服、隐私请求与内容举报：shybro027@gmail.com。完整隐私政策和使用条款将在公开发布前提供。';
}
