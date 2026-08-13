// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Listochek';

  @override
  String get appDescription => 'Minimalistic list';

  @override
  String get aboutApp => 'About';

  @override
  String get close => 'Close';

  @override
  String get settings => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get list => 'List';

  @override
  String get listEmpty => 'List is empty';

  @override
  String get listEmptyHint =>
      'Press the \"+\" button below\nto add an item\nData is saved automatically\nThe rows can be dragged';

  @override
  String get addItem => 'Add item';

  @override
  String get enterItem => 'Enter item name';

  @override
  String get add => 'Add';

  @override
  String get cancel => 'Cancel';

  @override
  String get clearAll => 'Clear list?';

  @override
  String get clearAllConfirm => 'All items will be deleted without recovery';

  @override
  String get clear => 'Clear';

  @override
  String get uncheckAll => 'Uncheck all?';

  @override
  String get uncheckAllConfirm => 'All items will be unchecked.';

  @override
  String get uncheck => 'Uncheck';

  @override
  String get listCleared => 'List cleared';

  @override
  String get uncheckedAll => 'All items unchecked';

  @override
  String get error => 'Error';

  @override
  String get fontSettings => 'Font settings';

  @override
  String get itemFont => 'List items font';

  @override
  String get titleFont => 'Title font';

  @override
  String get decrease => 'Decrease font';

  @override
  String get increase => 'Increase font';

  @override
  String get fontSize => 'Size';

  @override
  String get exampleText => 'Example text';

  @override
  String get exampleTitle => 'Example title';

  @override
  String get version => 'Version';

  @override
  String get inDevelopment => 'In development';

  @override
  String get openMenu => 'Open menu';

  @override
  String get uncheckAllTooltip => 'Uncheck all';

  @override
  String get clearAllTooltip => 'Clear list';

  @override
  String get aboutContentText =>
      '\n\nMinimalistic list management app\n\n©©️ Aleksei A. Kuzmin';

  @override
  String get errLoadSettings => 'Error loading settings';

  @override
  String get errSaveSettings => 'Error saving settings';

  @override
  String get errLoadList => 'Error loading the list';

  @override
  String get errSaveList => 'Error saving the list';

  @override
  String get loadingSettings => 'Loading settings...';
}
