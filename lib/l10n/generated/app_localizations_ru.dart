// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Листочек';

  @override
  String get appDescription => 'Минималистичный список';

  @override
  String get aboutApp => 'О приложении';

  @override
  String get close => 'Закрыть';

  @override
  String get settings => 'Настройки';

  @override
  String get profile => 'Профиль';

  @override
  String get list => 'Список';

  @override
  String get listEmpty => 'Список пуст';

  @override
  String get listEmptyHint =>
      'Нажмите на кнопку \"+\" внизу\nчтобы добавить строку\nДанные сохраняются автоматически\nСтроки можно перетаскивать';

  @override
  String get addItem => 'Добавить строку';

  @override
  String get enterItem => 'Введите строку';

  @override
  String get add => 'Добавить';

  @override
  String get cancel => 'Отмена';

  @override
  String get clearAll => 'Очистить список?';

  @override
  String get clearAllConfirm =>
      'Все строки будут удалены без возможности восстановления';

  @override
  String get clear => 'Очистить';

  @override
  String get uncheckAll => 'Снять пометку?';

  @override
  String get uncheckAllConfirm =>
      'Пометка будет снята у всех элементов списка.';

  @override
  String get uncheck => 'Снять';

  @override
  String get listCleared => 'Список очищен';

  @override
  String get uncheckedAll => 'Отметки сняты со всех элементов';

  @override
  String get error => 'Ошибка';

  @override
  String get fontSettings => 'Настройки шрифта';

  @override
  String get itemFont => 'Шрифт элементов списка';

  @override
  String get titleFont => 'Шрифт заголовка';

  @override
  String get decrease => 'Уменьшить шрифт';

  @override
  String get increase => 'Увеличить шрифт';

  @override
  String get fontSize => 'Размер';

  @override
  String get exampleText => 'Пример текста';

  @override
  String get exampleTitle => 'Пример заголовка';

  @override
  String get aboutContent => 'Минималистичное приложение для ведения списка.';

  @override
  String get copyright => '© Алексей А. Кузьмин';

  @override
  String get version => 'Версия';

  @override
  String get inDevelopment => 'В разработке';

  @override
  String get openMenu => 'Открыть меню';

  @override
  String get uncheckAllTooltip => 'Снять отметку у всех';

  @override
  String get clearAllTooltip => 'Очистить список';

  @override
  String get aboutContentText =>
      'ЛИСТОЧЕК v1.1.0\n\nМинималистичное приложение для ведения списка\n\n©️ Алексей А. Кузьмин';

  @override
  String get errLoadSettings => 'Ошибка загрузки настроек';

  @override
  String get errSaveSettings => 'Ошибка сохранения настроек';

  @override
  String get errLoadList => 'Ошибка загрузки списка';

  @override
  String get errSaveList => 'Ошибка сохранения списка';

  @override
  String get loadingSettings => 'Загрузка настроек...';
}
