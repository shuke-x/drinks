import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Tonight Drinks'**
  String get appTitle;

  /// No description provided for @newRecipe.
  ///
  /// In en, this message translates to:
  /// **'NEW RECIPE'**
  String get newRecipe;

  /// No description provided for @uploadCocktail.
  ///
  /// In en, this message translates to:
  /// **'Create cocktail'**
  String get uploadCocktail;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @englishNameLabel.
  ///
  /// In en, this message translates to:
  /// **'English name'**
  String get englishNameLabel;

  /// No description provided for @chineseNameHint.
  ///
  /// In en, this message translates to:
  /// **'Chinese name, e.g. Hawthorn Old Fashioned'**
  String get chineseNameHint;

  /// No description provided for @englishNameHint.
  ///
  /// In en, this message translates to:
  /// **'English name, e.g. Hawthorn Old Fashioned'**
  String get englishNameHint;

  /// No description provided for @baseSpirit.
  ///
  /// In en, this message translates to:
  /// **'Base spirit'**
  String get baseSpirit;

  /// No description provided for @themeColor.
  ///
  /// In en, this message translates to:
  /// **'Theme color'**
  String get themeColor;

  /// No description provided for @cocktailImages.
  ///
  /// In en, this message translates to:
  /// **'Cocktail images'**
  String get cocktailImages;

  /// No description provided for @createPrivateCocktail.
  ///
  /// In en, this message translates to:
  /// **'Create as a private cocktail'**
  String get createPrivateCocktail;

  /// No description provided for @privateCocktailDescription.
  ///
  /// In en, this message translates to:
  /// **'Owned by this account and manageable under Private Cocktails.'**
  String get privateCocktailDescription;

  /// No description provided for @publicCocktailDescription.
  ///
  /// In en, this message translates to:
  /// **'Save as a public draft, then submit it for review when ready.'**
  String get publicCocktailDescription;

  /// No description provided for @ingredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get ingredients;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @ingredient.
  ///
  /// In en, this message translates to:
  /// **'Ingredient'**
  String get ingredient;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @stepsPerLine.
  ///
  /// In en, this message translates to:
  /// **'METHOD · ONE STEP PER LINE'**
  String get stepsPerLine;

  /// No description provided for @stepsHint.
  ///
  /// In en, this message translates to:
  /// **'Stir until chilled\nStrain into an old fashioned glass'**
  String get stepsHint;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @addToMyCocktails.
  ///
  /// In en, this message translates to:
  /// **'Add to my cocktails'**
  String get addToMyCocktails;

  /// No description provided for @createCocktail.
  ///
  /// In en, this message translates to:
  /// **'Create cocktail'**
  String get createCocktail;

  /// No description provided for @enterChineseName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a cocktail name'**
  String get enterChineseName;

  /// No description provided for @validationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a cocktail name'**
  String get validationNameRequired;

  /// No description provided for @validationSpiritRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a base spirit'**
  String get validationSpiritRequired;

  /// No description provided for @validationRecipeRequired.
  ///
  /// In en, this message translates to:
  /// **'Add at least one ingredient'**
  String get validationRecipeRequired;

  /// No description provided for @validationStepsRequired.
  ///
  /// In en, this message translates to:
  /// **'Add the preparation steps'**
  String get validationStepsRequired;

  /// No description provided for @validationImagesRequired.
  ///
  /// In en, this message translates to:
  /// **'Add at least one cocktail image'**
  String get validationImagesRequired;

  /// No description provided for @validationPrivateSubmit.
  ///
  /// In en, this message translates to:
  /// **'Private cocktails cannot be submitted for review'**
  String get validationPrivateSubmit;

  /// No description provided for @saveDraftPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Save draft?'**
  String get saveDraftPromptTitle;

  /// No description provided for @saveDraftPromptBody.
  ///
  /// In en, this message translates to:
  /// **'Your current content will be saved as a draft so you can finish and submit it later.'**
  String get saveDraftPromptBody;

  /// No description provided for @saveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get saveDraft;

  /// No description provided for @saveDraftAndExit.
  ///
  /// In en, this message translates to:
  /// **'Save draft and exit'**
  String get saveDraftAndExit;

  /// No description provided for @leaveWithoutSaving.
  ///
  /// In en, this message translates to:
  /// **'Leave without saving'**
  String get leaveWithoutSaving;

  /// No description provided for @imageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'{count} image(s) exceeded 15 MB and were skipped'**
  String imageTooLarge(Object count);

  /// No description provided for @selectImagesAgain.
  ///
  /// In en, this message translates to:
  /// **'An image failed validation. Select images again before submitting.'**
  String get selectImagesAgain;

  /// No description provided for @uploadInvalidImage.
  ///
  /// In en, this message translates to:
  /// **'The image format or file content is invalid.'**
  String get uploadInvalidImage;

  /// No description provided for @uploadImageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The image is too large.'**
  String get uploadImageTooLarge;

  /// No description provided for @uploadTooFrequent.
  ///
  /// In en, this message translates to:
  /// **'You\'re uploading too frequently. Please try again later.'**
  String get uploadTooFrequent;

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updated;

  /// No description provided for @privateCocktailCreated.
  ///
  /// In en, this message translates to:
  /// **'Private cocktail created'**
  String get privateCocktailCreated;

  /// No description provided for @publicDraftCreated.
  ///
  /// In en, this message translates to:
  /// **'Public cocktail draft saved'**
  String get publicDraftCreated;

  /// No description provided for @addedToMyCocktails.
  ///
  /// In en, this message translates to:
  /// **'Added to my cocktails'**
  String get addedToMyCocktails;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Please try again later.'**
  String get uploadFailed;

  /// No description provided for @imagePreview.
  ///
  /// In en, this message translates to:
  /// **'Image preview'**
  String get imagePreview;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @discardChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardChangesTitle;

  /// No description provided for @discardChangesBody.
  ///
  /// In en, this message translates to:
  /// **'Your unsaved cocktail changes will be lost.'**
  String get discardChangesBody;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @todayDrink.
  ///
  /// In en, this message translates to:
  /// **'What should we drink?'**
  String get todayDrink;

  /// No description provided for @loginToCreate.
  ///
  /// In en, this message translates to:
  /// **'Sign in to create a cocktail'**
  String get loginToCreate;

  /// No description provided for @tapToLogin.
  ///
  /// In en, this message translates to:
  /// **'Tap to sign in'**
  String get tapToLogin;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Tap to edit profile'**
  String get editProfile;

  /// No description provided for @loginManageCocktails.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage your cocktails'**
  String get loginManageCocktails;

  /// No description provided for @myFavorites.
  ///
  /// In en, this message translates to:
  /// **'My favorites'**
  String get myFavorites;

  /// No description provided for @favoriteCount.
  ///
  /// In en, this message translates to:
  /// **'{count} saved cocktail(s)'**
  String favoriteCount(Object count);

  /// No description provided for @loginToFavoriteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save cocktails you like'**
  String get loginToFavoriteSubtitle;

  /// No description provided for @unitsAndCalculation.
  ///
  /// In en, this message translates to:
  /// **'Units & calculation'**
  String get unitsAndCalculation;

  /// No description provided for @milliliterDescription.
  ///
  /// In en, this message translates to:
  /// **'Recipe amounts are shown in milliliters'**
  String get milliliterDescription;

  /// No description provided for @ounceDescription.
  ///
  /// In en, this message translates to:
  /// **'Recipe amounts are shown in ounces'**
  String get ounceDescription;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get languageSystem;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get languageChinese;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageDescription.
  ///
  /// In en, this message translates to:
  /// **'Current: {language}'**
  String languageDescription(Object language);

  /// No description provided for @loginToFavorite.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save favorites'**
  String get loginToFavorite;

  /// No description provided for @favoriteAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get favoriteAdded;

  /// No description provided for @favoriteRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get favoriteRemoved;

  /// No description provided for @favoriteSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sync favorite. Try again later.'**
  String get favoriteSyncFailed;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Please sign in again.'**
  String get sessionExpired;

  /// No description provided for @categoryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load spirit categories. Try again.'**
  String get categoryLoadFailed;

  /// No description provided for @suitableAmount.
  ///
  /// In en, this message translates to:
  /// **'To taste'**
  String get suitableAmount;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get home;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Inspire'**
  String get next;

  /// No description provided for @records.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get records;

  /// No description provided for @recipes.
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get recipes;

  /// No description provided for @recommend.
  ///
  /// In en, this message translates to:
  /// **'Flavor'**
  String get recommend;

  /// No description provided for @cocktails.
  ///
  /// In en, this message translates to:
  /// **'Cellar'**
  String get cocktails;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get user;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchCocktails.
  ///
  /// In en, this message translates to:
  /// **'Search cocktails'**
  String get searchCocktails;

  /// No description provided for @searchCocktailsHint.
  ///
  /// In en, this message translates to:
  /// **'Search names, spirits, tags, or ingredients'**
  String get searchCocktailsHint;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matching cocktails'**
  String get searchNoResults;

  /// No description provided for @searchNoResultsHint.
  ///
  /// In en, this message translates to:
  /// **'Try another name, spirit, or ingredient.'**
  String get searchNoResultsHint;

  /// No description provided for @emptyCocktails.
  ///
  /// In en, this message translates to:
  /// **'No cocktails here yet'**
  String get emptyCocktails;

  /// No description provided for @cocktailsPreparing.
  ///
  /// In en, this message translates to:
  /// **'Cocktails are being prepared. Check back soon.'**
  String get cocktailsPreparing;

  /// No description provided for @tryAnotherCategory.
  ///
  /// In en, this message translates to:
  /// **'Try another category and discover a different flavor.'**
  String get tryAnotherCategory;

  /// No description provided for @noCocktailOptions.
  ///
  /// In en, this message translates to:
  /// **'No cocktails to choose from yet'**
  String get noCocktailOptions;

  /// No description provided for @optionsPreparing.
  ///
  /// In en, this message translates to:
  /// **'Come back when the cocktail list is ready.'**
  String get optionsPreparing;

  /// No description provided for @noFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get noFavorites;

  /// No description provided for @favoriteEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on a cocktail detail page.'**
  String get favoriteEmptyHint;

  /// No description provided for @privateCocktails.
  ///
  /// In en, this message translates to:
  /// **'My cocktails'**
  String get privateCocktails;

  /// No description provided for @privateCocktailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s drafts, private recipes, and published cocktails'**
  String privateCocktailSubtitle(Object name);

  /// No description provided for @privateCocktailEmpty.
  ///
  /// In en, this message translates to:
  /// **'Cocktails you create will appear here'**
  String get privateCocktailEmpty;

  /// No description provided for @privateCocktailEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Create a private cocktail or submit one for public review.'**
  String get privateCocktailEmptyHint;

  /// No description provided for @designPrivateCocktail.
  ///
  /// In en, this message translates to:
  /// **'Design yours'**
  String get designPrivateCocktail;

  /// No description provided for @cocktailStatusAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get cocktailStatusAll;

  /// No description provided for @cocktailStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get cocktailStatusDraft;

  /// No description provided for @cocktailStatusPending.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get cocktailStatusPending;

  /// No description provided for @cocktailStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Needs changes'**
  String get cocktailStatusRejected;

  /// No description provided for @cocktailStatusPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get cocktailStatusPublished;

  /// No description provided for @cocktailStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get cocktailStatusOffline;

  /// No description provided for @cocktailStatusPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get cocktailStatusPrivate;

  /// No description provided for @submitForReview.
  ///
  /// In en, this message translates to:
  /// **'Submit for review'**
  String get submitForReview;

  /// No description provided for @withdrawReview.
  ///
  /// In en, this message translates to:
  /// **'Withdraw review'**
  String get withdrawReview;

  /// No description provided for @editCocktail.
  ///
  /// In en, this message translates to:
  /// **'Edit cocktail'**
  String get editCocktail;

  /// No description provided for @deleteCocktail.
  ///
  /// In en, this message translates to:
  /// **'Delete cocktail'**
  String get deleteCocktail;

  /// No description provided for @deleteDraft.
  ///
  /// In en, this message translates to:
  /// **'Delete draft'**
  String get deleteDraft;

  /// No description provided for @deleteDraftTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this draft?'**
  String get deleteDraftTitle;

  /// No description provided for @deleteDraftBody.
  ///
  /// In en, this message translates to:
  /// **'This draft cannot be recovered after deletion.'**
  String get deleteDraftBody;

  /// No description provided for @deleteCocktailTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this cocktail?'**
  String get deleteCocktailTitle;

  /// No description provided for @deleteCocktailBody.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deleteCocktailBody;

  /// No description provided for @cocktailSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted for review'**
  String get cocktailSubmitted;

  /// No description provided for @cocktailWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Review withdrawn'**
  String get cocktailWithdrawn;

  /// No description provided for @cocktailDeleted.
  ///
  /// In en, this message translates to:
  /// **'Cocktail deleted'**
  String get cocktailDeleted;

  /// No description provided for @cocktailActionFailed.
  ///
  /// In en, this message translates to:
  /// **'The action failed. Try again later.'**
  String get cocktailActionFailed;

  /// No description provided for @reviewReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String reviewReason(Object reason);

  /// No description provided for @ingredientCount.
  ///
  /// In en, this message translates to:
  /// **'{base} · {count} ingredients'**
  String ingredientCount(Object base, Object count);

  /// No description provided for @recipeUnit.
  ///
  /// In en, this message translates to:
  /// **'RECIPE · {unit}'**
  String recipeUnit(Object unit);

  /// No description provided for @milliliters.
  ///
  /// In en, this message translates to:
  /// **'milliliters'**
  String get milliliters;

  /// No description provided for @ounces.
  ///
  /// In en, this message translates to:
  /// **'ounces'**
  String get ounces;

  /// No description provided for @method.
  ///
  /// In en, this message translates to:
  /// **'METHOD'**
  String get method;

  /// No description provided for @flavorStory.
  ///
  /// In en, this message translates to:
  /// **'FLAVOR STORY'**
  String get flavorStory;

  /// No description provided for @flavorImpression.
  ///
  /// In en, this message translates to:
  /// **'FLAVOR IMPRESSION'**
  String get flavorImpression;

  /// No description provided for @tonightThisOne.
  ///
  /// In en, this message translates to:
  /// **'This is the one'**
  String get tonightThisOne;

  /// No description provided for @viewRecipe.
  ///
  /// In en, this message translates to:
  /// **'View recipe'**
  String get viewRecipe;

  /// No description provided for @drawAgain.
  ///
  /// In en, this message translates to:
  /// **'Draw again'**
  String get drawAgain;

  /// No description provided for @validEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get validEmailRequired;

  /// No description provided for @passwordSixCharacters.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordSixCharacters;

  /// No description provided for @nicknameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a nickname'**
  String get nicknameRequired;

  /// No description provided for @passwordPolicy.
  ///
  /// In en, this message translates to:
  /// **'Use 8+ characters with uppercase, lowercase, a number, and punctuation'**
  String get passwordPolicy;

  /// No description provided for @registerWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome — your account is ready'**
  String get registerWelcome;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}'**
  String welcomeBack(Object name);

  /// No description provided for @authFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please try again later.'**
  String get authFailed;

  /// No description provided for @authHero.
  ///
  /// In en, this message translates to:
  /// **'Tonight, drink something good.'**
  String get authHero;

  /// No description provided for @authSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save the flavors worth another glass'**
  String get authSubtitle;

  /// No description provided for @nickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nickname;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @startCreating.
  ///
  /// In en, this message translates to:
  /// **'Start creating privately'**
  String get startCreating;

  /// No description provided for @continueTonight.
  ///
  /// In en, this message translates to:
  /// **'Continue exploring tonight'**
  String get continueTonight;

  /// No description provided for @notLoginNow.
  ///
  /// In en, this message translates to:
  /// **'Not ready to sign in?'**
  String get notLoginNow;

  /// No description provided for @browseAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Browse as guest'**
  String get browseAsGuest;

  /// No description provided for @nicknameCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nickname cannot be empty'**
  String get nicknameCannotBeEmpty;

  /// No description provided for @profileSynced.
  ///
  /// In en, this message translates to:
  /// **'Profile synced'**
  String get profileSynced;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Please try again later.'**
  String get saveFailed;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Your account, favorites, private cocktails, and related images will be permanently deleted. Published cocktails will remain anonymously under “Deleted publisher.” This cannot be undone.'**
  String get deleteAccountBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @currentSelection.
  ///
  /// In en, this message translates to:
  /// **'CURRENT SELECTION'**
  String get currentSelection;

  /// No description provided for @deletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get deletePermanently;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get accountDeleted;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the account. Please try again later.'**
  String get deleteFailed;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @startRecordingTaste.
  ///
  /// In en, this message translates to:
  /// **'Start recording your taste'**
  String get startRecordingTaste;

  /// No description provided for @loginStart.
  ///
  /// In en, this message translates to:
  /// **'Sign in / Get started'**
  String get loginStart;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing…'**
  String get processing;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get saveProfile;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logout;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @unitSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All recipe amounts convert instantly to your preference.'**
  String get unitSettingsSubtitle;

  /// No description provided for @measurementUnit.
  ///
  /// In en, this message translates to:
  /// **'Measurement unit'**
  String get measurementUnit;

  /// No description provided for @milliliterMode.
  ///
  /// In en, this message translates to:
  /// **'Milliliter mode: recipes display in ml.'**
  String get milliliterMode;

  /// No description provided for @ounceMode.
  ///
  /// In en, this message translates to:
  /// **'Ounce mode: values round to the nearest 1/4 oz.'**
  String get ounceMode;

  /// No description provided for @glassware.
  ///
  /// In en, this message translates to:
  /// **'GLASSWARE'**
  String get glassware;

  /// No description provided for @garnish.
  ///
  /// In en, this message translates to:
  /// **'GARNISH'**
  String get garnish;

  /// No description provided for @loginBenefits.
  ///
  /// In en, this message translates to:
  /// **'Sign in to edit your avatar, save favorites, and use private cocktail space.'**
  String get loginBenefits;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @swipeHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe to browse · Tap a card for the recipe'**
  String get swipeHint;

  /// No description provided for @featuredToday.
  ///
  /// In en, this message translates to:
  /// **'FEATURED TODAY'**
  String get featuredToday;

  /// No description provided for @resultFlavor.
  ///
  /// In en, this message translates to:
  /// **'{flavor} Let {base} lead the way tonight.'**
  String resultFlavor(Object base, Object flavor);

  /// No description provided for @privateTag.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get privateTag;

  /// No description provided for @yourPreferredGlass.
  ///
  /// In en, this message translates to:
  /// **'Your choice'**
  String get yourPreferredGlass;

  /// No description provided for @freeGarnish.
  ///
  /// In en, this message translates to:
  /// **'Your choice'**
  String get freeGarnish;

  /// No description provided for @personalFlavor.
  ///
  /// In en, this message translates to:
  /// **'A cocktail of your own.'**
  String get personalFlavor;

  /// No description provided for @personalStory.
  ///
  /// In en, this message translates to:
  /// **'You define this glass.'**
  String get personalStory;

  /// No description provided for @languageSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sync your language preference. Try again later.'**
  String get languageSyncFailed;

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load'**
  String get loadFailed;

  /// No description provided for @loadFailedDescription.
  ///
  /// In en, this message translates to:
  /// **'The request failed or timed out. Please try again.'**
  String get loadFailedDescription;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @cocktailNotFound.
  ///
  /// In en, this message translates to:
  /// **'This cocktail couldn\'t be found'**
  String get cocktailNotFound;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavorites;

  /// No description provided for @removeIngredient.
  ///
  /// In en, this message translates to:
  /// **'Remove ingredient'**
  String get removeIngredient;

  /// No description provided for @photoAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Photo access is unavailable. Allow access in Settings, then try again.'**
  String get photoAccessDenied;

  /// No description provided for @photoReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read the photo. Please choose it again.'**
  String get photoReadFailed;

  /// No description provided for @privacyAndUse.
  ///
  /// In en, this message translates to:
  /// **'Privacy and use'**
  String get privacyAndUse;

  /// No description provided for @privacyAndUseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Data use, age requirements, and account controls'**
  String get privacyAndUseSubtitle;

  /// No description provided for @privacyDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Data we process'**
  String get privacyDataTitle;

  /// No description provided for @privacyDataBody.
  ///
  /// In en, this message translates to:
  /// **'Account features use your email, nickname, and account ID. Your uploaded avatar, recipes, favorites, and tasting records are sent to the server for storage and synchronization. Records may include photos, venues, prices, and notes. Search terms are sent to the server to retrieve results.'**
  String get privacyDataBody;

  /// No description provided for @privacyPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo selection'**
  String get privacyPhotosTitle;

  /// No description provided for @privacyPhotosBody.
  ///
  /// In en, this message translates to:
  /// **'The system photo picker opens when you choose to add photos to your profile, recipes, or tasting records. Cancelling preserves your existing input.'**
  String get privacyPhotosBody;

  /// No description provided for @privacyDiagnosticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Error diagnostics'**
  String get privacyDiagnosticsTitle;

  /// No description provided for @privacyDiagnosticsBody.
  ///
  /// In en, this message translates to:
  /// **'App error diagnostics send only an error category, a grouping identifier derived from code locations, and the platform. They do not include tokens, email addresses, notes, photos, or raw exception content.'**
  String get privacyDiagnosticsBody;

  /// No description provided for @privacyAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account and content'**
  String get privacyAccountTitle;

  /// No description provided for @privacyAccountBody.
  ///
  /// In en, this message translates to:
  /// **'You can permanently delete your account from your profile details. Published recipes may remain with an anonymous author; read the confirmation before deleting. Avoid including private information in public content.'**
  String get privacyAccountBody;

  /// No description provided for @responsibleUseTitle.
  ///
  /// In en, this message translates to:
  /// **'Age and responsible use'**
  String get responsibleUseTitle;

  /// No description provided for @responsibleUseBody.
  ///
  /// In en, this message translates to:
  /// **'This app is intended for users aged 18 and over. Follow local requirements where the legal drinking age is higher. Drink responsibly and never drive after drinking. Recipes are provided for reference.'**
  String get responsibleUseBody;

  /// No description provided for @privacyPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Support and reports'**
  String get privacyPendingTitle;

  /// No description provided for @privacyPendingBody.
  ///
  /// In en, this message translates to:
  /// **'For support, privacy requests, and content reports: shybro027@gmail.com. The full privacy policy and terms will be provided before public release.'**
  String get privacyPendingBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
