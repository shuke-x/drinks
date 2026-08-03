// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Tonight Drinks';

  @override
  String get newRecipe => 'NEW RECIPE';

  @override
  String get uploadCocktail => 'Create cocktail';

  @override
  String get nameLabel => 'Name';

  @override
  String get englishNameLabel => 'English name';

  @override
  String get chineseNameHint => 'Chinese name, e.g. Hawthorn Old Fashioned';

  @override
  String get englishNameHint => 'English name, e.g. Hawthorn Old Fashioned';

  @override
  String get baseSpirit => 'Base spirit';

  @override
  String get themeColor => 'Theme color';

  @override
  String get cocktailImages => 'Cocktail images';

  @override
  String get createPrivateCocktail => 'Create as a private cocktail';

  @override
  String get privateCocktailDescription =>
      'Owned by this account and manageable under Private Cocktails.';

  @override
  String get publicCocktailDescription =>
      'Save as a public draft, then submit it for review when ready.';

  @override
  String get ingredients => 'Ingredients';

  @override
  String get add => 'Add';

  @override
  String get ingredient => 'Ingredient';

  @override
  String get amount => 'Amount';

  @override
  String get stepsPerLine => 'METHOD · ONE STEP PER LINE';

  @override
  String get stepsHint =>
      'Stir until chilled\nStrain into an old fashioned glass';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get addToMyCocktails => 'Add to my cocktails';

  @override
  String get createCocktail => 'Create cocktail';

  @override
  String get enterChineseName => 'Please enter a cocktail name';

  @override
  String get validationNameRequired => 'Enter a cocktail name';

  @override
  String get validationSpiritRequired => 'Select a base spirit';

  @override
  String get validationRecipeRequired => 'Add at least one ingredient';

  @override
  String get validationStepsRequired => 'Add the preparation steps';

  @override
  String get validationImagesRequired => 'Add at least one cocktail image';

  @override
  String get validationPrivateSubmit =>
      'Private cocktails cannot be submitted for review';

  @override
  String get saveDraftPromptTitle => 'Save draft?';

  @override
  String get saveDraftPromptBody =>
      'Your current content will be saved as a draft so you can finish and submit it later.';

  @override
  String get saveDraft => 'Save draft';

  @override
  String get saveDraftAndExit => 'Save draft and exit';

  @override
  String get leaveWithoutSaving => 'Leave without saving';

  @override
  String imageTooLarge(Object count) {
    return '$count image(s) exceeded 15 MB and were skipped';
  }

  @override
  String get selectImagesAgain =>
      'An image failed validation. Select images again before submitting.';

  @override
  String get uploadInvalidImage =>
      'The image format or file content is invalid.';

  @override
  String get uploadImageTooLarge => 'The image is too large.';

  @override
  String get uploadTooFrequent =>
      'You\'re uploading too frequently. Please try again later.';

  @override
  String get updated => 'Updated';

  @override
  String get privateCocktailCreated => 'Private cocktail created';

  @override
  String get publicDraftCreated => 'Public cocktail draft saved';

  @override
  String get addedToMyCocktails => 'Added to my cocktails';

  @override
  String get uploadFailed => 'Upload failed. Please try again later.';

  @override
  String get imagePreview => 'Image preview';

  @override
  String get close => 'Close';

  @override
  String get discardChangesTitle => 'Discard changes?';

  @override
  String get discardChangesBody =>
      'Your unsaved cocktail changes will be lost.';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get discard => 'Discard';

  @override
  String get todayDrink => 'What should we drink?';

  @override
  String get loginToCreate => 'Sign in to create a cocktail';

  @override
  String get tapToLogin => 'Tap to sign in';

  @override
  String get editProfile => 'Tap to edit profile';

  @override
  String get loginManageCocktails => 'Sign in to manage your cocktails';

  @override
  String get myFavorites => 'My favorites';

  @override
  String favoriteCount(Object count) {
    return '$count saved cocktail(s)';
  }

  @override
  String get loginToFavoriteSubtitle => 'Sign in to save cocktails you like';

  @override
  String get unitsAndCalculation => 'Units & calculation';

  @override
  String get milliliterDescription => 'Recipe amounts are shown in milliliters';

  @override
  String get ounceDescription => 'Recipe amounts are shown in ounces';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Follow system';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageEnglish => 'English';

  @override
  String languageDescription(Object language) {
    return 'Current: $language';
  }

  @override
  String get loginToFavorite => 'Sign in to save favorites';

  @override
  String get favoriteAdded => 'Added to favorites';

  @override
  String get favoriteRemoved => 'Removed from favorites';

  @override
  String get favoriteSyncFailed => 'Couldn\'t sync favorite. Try again later.';

  @override
  String get sessionExpired => 'Your session expired. Please sign in again.';

  @override
  String get categoryLoadFailed =>
      'Couldn\'t load spirit categories. Try again.';

  @override
  String get suitableAmount => 'To taste';

  @override
  String get home => 'Discover';

  @override
  String get all => 'All';

  @override
  String get next => 'Inspire';

  @override
  String get cocktails => 'Cellar';

  @override
  String get user => 'Profile';

  @override
  String get emptyCocktails => 'No cocktails here yet';

  @override
  String get cocktailsPreparing =>
      'Cocktails are being prepared. Check back soon.';

  @override
  String get tryAnotherCategory =>
      'Try another category and discover a different flavor.';

  @override
  String get noCocktailOptions => 'No cocktails to choose from yet';

  @override
  String get optionsPreparing => 'Come back when the cocktail list is ready.';

  @override
  String get noFavorites => 'No favorites yet';

  @override
  String get favoriteEmptyHint => 'Tap the heart on a cocktail detail page.';

  @override
  String get privateCocktails => 'My cocktails';

  @override
  String privateCocktailSubtitle(Object name) {
    return '$name\'s drafts, private recipes, and published cocktails';
  }

  @override
  String get privateCocktailEmpty => 'Cocktails you create will appear here';

  @override
  String get privateCocktailEmptyHint =>
      'Create a private cocktail or submit one for public review.';

  @override
  String get designPrivateCocktail => 'Design yours';

  @override
  String get cocktailStatusAll => 'All';

  @override
  String get cocktailStatusDraft => 'Draft';

  @override
  String get cocktailStatusPending => 'In review';

  @override
  String get cocktailStatusRejected => 'Needs changes';

  @override
  String get cocktailStatusPublished => 'Published';

  @override
  String get cocktailStatusOffline => 'Offline';

  @override
  String get cocktailStatusPrivate => 'Private';

  @override
  String get submitForReview => 'Submit for review';

  @override
  String get withdrawReview => 'Withdraw review';

  @override
  String get editCocktail => 'Edit cocktail';

  @override
  String get deleteCocktail => 'Delete cocktail';

  @override
  String get deleteDraft => 'Delete draft';

  @override
  String get deleteDraftTitle => 'Delete this draft?';

  @override
  String get deleteDraftBody =>
      'This draft cannot be recovered after deletion.';

  @override
  String get deleteCocktailTitle => 'Delete this cocktail?';

  @override
  String get deleteCocktailBody => 'This action cannot be undone.';

  @override
  String get cocktailSubmitted => 'Submitted for review';

  @override
  String get cocktailWithdrawn => 'Review withdrawn';

  @override
  String get cocktailDeleted => 'Cocktail deleted';

  @override
  String get cocktailActionFailed => 'The action failed. Try again later.';

  @override
  String reviewReason(Object reason) {
    return 'Reason: $reason';
  }

  @override
  String ingredientCount(Object base, Object count) {
    return '$base · $count ingredients';
  }

  @override
  String recipeUnit(Object unit) {
    return 'RECIPE · $unit';
  }

  @override
  String get milliliters => 'milliliters';

  @override
  String get ounces => 'ounces';

  @override
  String get method => 'METHOD';

  @override
  String get flavorStory => 'FLAVOR STORY';

  @override
  String get tonightThisOne => 'This is the one';

  @override
  String get viewRecipe => 'View recipe';

  @override
  String get drawAgain => 'Draw again';

  @override
  String get validEmailRequired => 'Enter a valid email address';

  @override
  String get passwordSixCharacters => 'Password must be at least 6 characters';

  @override
  String get nicknameRequired => 'Enter a nickname';

  @override
  String get passwordPolicy =>
      'Use 8+ characters with uppercase, lowercase, a number, and punctuation';

  @override
  String get registerWelcome => 'Welcome — your account is ready';

  @override
  String welcomeBack(Object name) {
    return 'Welcome back, $name';
  }

  @override
  String get authFailed => 'Authentication failed. Please try again later.';

  @override
  String get authHero => 'Tonight, drink something good.';

  @override
  String get authSubtitle => 'Save the flavors worth another glass';

  @override
  String get nickname => 'Nickname';

  @override
  String get emailAddress => 'Email address';

  @override
  String get password => 'Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get startCreating => 'Start creating privately';

  @override
  String get continueTonight => 'Continue exploring tonight';

  @override
  String get notLoginNow => 'Not ready to sign in?';

  @override
  String get browseAsGuest => 'Browse as guest';

  @override
  String get nicknameCannotBeEmpty => 'Nickname cannot be empty';

  @override
  String get profileSynced => 'Profile synced';

  @override
  String get saveFailed => 'Couldn\'t save. Please try again later.';

  @override
  String get deleteAccountTitle => 'Permanently delete account?';

  @override
  String get deleteAccountBody =>
      'Your account, favorites, private cocktails, and related images will be permanently deleted. Published cocktails will remain anonymously under “Deleted publisher.” This cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get done => 'Done';

  @override
  String get currentSelection => 'CURRENT SELECTION';

  @override
  String get deletePermanently => 'Delete permanently';

  @override
  String get accountDeleted => 'Account deleted';

  @override
  String get deleteFailed =>
      'Couldn\'t delete the account. Please try again later.';

  @override
  String get profile => 'Profile';

  @override
  String get startRecordingTaste => 'Start recording your taste';

  @override
  String get loginStart => 'Sign in / Get started';

  @override
  String get enterYourName => 'Enter your name';

  @override
  String get processing => 'Processing…';

  @override
  String get saveProfile => 'Save profile';

  @override
  String get logout => 'Sign out';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get unitSettingsSubtitle =>
      'All recipe amounts convert instantly to your preference.';

  @override
  String get measurementUnit => 'Measurement unit';

  @override
  String get milliliterMode => 'Milliliter mode: recipes display in ml.';

  @override
  String get ounceMode => 'Ounce mode: values round to the nearest 1/4 oz.';

  @override
  String get glassware => 'GLASSWARE';

  @override
  String get garnish => 'GARNISH';

  @override
  String get loginBenefits =>
      'Sign in to edit your avatar, save favorites, and use private cocktail space.';

  @override
  String get login => 'Sign in';

  @override
  String get register => 'Register';

  @override
  String get swipeHint => 'Swipe to browse · Tap a card for the recipe';

  @override
  String get featuredToday => 'FEATURED TODAY';

  @override
  String resultFlavor(Object base, Object flavor) {
    return '$flavor Let $base lead the way tonight.';
  }

  @override
  String get privateTag => 'Private';

  @override
  String get yourPreferredGlass => 'Your choice';

  @override
  String get freeGarnish => 'Your choice';

  @override
  String get personalFlavor => 'A cocktail of your own.';

  @override
  String get personalStory => 'You define this glass.';

  @override
  String get languageSyncFailed =>
      'Couldn\'t sync your language preference. Try again later.';

  @override
  String get loadFailed => 'Couldn\'t load';

  @override
  String get loadFailedDescription =>
      'The request failed or timed out. Please try again.';

  @override
  String get retry => 'Try again';

  @override
  String get cocktailNotFound => 'This cocktail couldn\'t be found';

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get removeIngredient => 'Remove ingredient';
}
