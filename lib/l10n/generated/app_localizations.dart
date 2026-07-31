import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ru, this message translates to:
  /// **'Листочек'**
  String get appTitle;

  /// No description provided for @appDescription.
  ///
  /// In ru, this message translates to:
  /// **'Минималистичный список'**
  String get appDescription;

  /// No description provided for @aboutApp.
  ///
  /// In ru, this message translates to:
  /// **'О приложении'**
  String get aboutApp;

  /// No description provided for @close.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get close;

  /// No description provided for @settings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settings;

  /// No description provided for @profile.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get profile;

  /// No description provided for @list.
  ///
  /// In ru, this message translates to:
  /// **'Список'**
  String get list;

  /// No description provided for @listEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Список пуст'**
  String get listEmpty;

  /// No description provided for @listEmptyHint.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите на кнопку \"+\" внизу\nчтобы добавить строку\nДанные сохраняются автоматически'**
  String get listEmptyHint;

  /// No description provided for @addItem.
  ///
  /// In ru, this message translates to:
  /// **'Добавить строку'**
  String get addItem;

  /// No description provided for @enterItem.
  ///
  /// In ru, this message translates to:
  /// **'Введите строку'**
  String get enterItem;

  /// No description provided for @add.
  ///
  /// In ru, this message translates to:
  /// **'Добавить'**
  String get add;

  /// No description provided for @cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancel;

  /// No description provided for @clearAll.
  ///
  /// In ru, this message translates to:
  /// **'Очистить список'**
  String get clearAll;

  /// No description provided for @clearAllConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Все строки будут удалены без возможности восстановления'**
  String get clearAllConfirm;

  /// No description provided for @clear.
  ///
  /// In ru, this message translates to:
  /// **'Очистить'**
  String get clear;

  /// No description provided for @uncheckAll.
  ///
  /// In ru, this message translates to:
  /// **'Снять пометку?'**
  String get uncheckAll;

  /// No description provided for @uncheckAllConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Пометка будет снята у всех элементов списка.'**
  String get uncheckAllConfirm;

  /// No description provided for @uncheck.
  ///
  /// In ru, this message translates to:
  /// **'Снять'**
  String get uncheck;

  /// No description provided for @listCleared.
  ///
  /// In ru, this message translates to:
  /// **'Список очищен'**
  String get listCleared;

  /// No description provided for @uncheckedAll.
  ///
  /// In ru, this message translates to:
  /// **'Отметки сняты со всех элементов'**
  String get uncheckedAll;

  /// No description provided for @error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка'**
  String get error;

  /// No description provided for @fontSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки шрифта'**
  String get fontSettings;

  /// No description provided for @itemFont.
  ///
  /// In ru, this message translates to:
  /// **'Шрифт элементов списка'**
  String get itemFont;

  /// No description provided for @titleFont.
  ///
  /// In ru, this message translates to:
  /// **'Шрифт заголовка'**
  String get titleFont;

  /// No description provided for @decrease.
  ///
  /// In ru, this message translates to:
  /// **'Уменьшить шрифт'**
  String get decrease;

  /// No description provided for @increase.
  ///
  /// In ru, this message translates to:
  /// **'Увеличить шрифт'**
  String get increase;

  /// No description provided for @fontSize.
  ///
  /// In ru, this message translates to:
  /// **'Размер'**
  String get fontSize;

  /// No description provided for @exampleText.
  ///
  /// In ru, this message translates to:
  /// **'Пример текста'**
  String get exampleText;

  /// No description provided for @exampleTitle.
  ///
  /// In ru, this message translates to:
  /// **'Пример заголовка'**
  String get exampleTitle;

  /// No description provided for @aboutContent.
  ///
  /// In ru, this message translates to:
  /// **'Минималистичное приложение для ведения списка.'**
  String get aboutContent;

  /// No description provided for @copyright.
  ///
  /// In ru, this message translates to:
  /// **'© Алексей А. Кузьмин'**
  String get copyright;

  /// No description provided for @version.
  ///
  /// In ru, this message translates to:
  /// **'Версия'**
  String get version;

  /// No description provided for @inDevelopment.
  ///
  /// In ru, this message translates to:
  /// **'В разработке'**
  String get inDevelopment;

  /// No description provided for @openMenu.
  ///
  /// In ru, this message translates to:
  /// **'Открыть меню'**
  String get openMenu;

  /// No description provided for @uncheckAllTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Снять отметку у всех'**
  String get uncheckAllTooltip;

  /// No description provided for @clearAllTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Очистить список'**
  String get clearAllTooltip;

  /// No description provided for @aboutContentText.
  ///
  /// In ru, this message translates to:
  /// **'ЛИСТОЧЕК v1.1.0\n\nМинималистичное приложение для ведения списка\n\n©️ Алексей А. Кузьмин'**
  String get aboutContentText;
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
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
