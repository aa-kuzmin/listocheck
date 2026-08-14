import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:listocheck/models/checklist_item.dart';

//import '../main.dart';
import 'settings_service.dart';
import 'list_service.dart';
import '../constants.dart';
import '../utils/errors.dart';

class ListNotifier extends Notifier<ListService> {
  bool _isLoaded = false;

  @override
  ListService build() {
    // Инициализируем начальное состояние
    return ListService([]);
  }

  Future<void> loadList() async {
    // Если уже загружено, не загружаем снова
    if (_isLoaded) return;

    final result = await ListService.load();

    if (result is Success) {
      final service = result.data ?? ListService([]);
      state = service;
    } else {
      // Ошибка загрузки - оставляем список пустым
      state = ListService([]);
    }
   _isLoaded = true;
  }

  // Приватный метод для сохранения
  Future<void> _saveList() async {
    await state.save();
  }

  // Очистить список
  void clear() {
    state = ListService([]);
    _saveList();
  }

  // Снять пометки у всего списка
  void uncheckAllItems() {
    var list = state.items;
    for (var item in list) {
      item.isChecked = false;
    }
    state = ListService(list);
    _saveList();
  }

  // Изменить отметку у строки
  void toggleItem(int index) {
    var list = state.items;
    list[index].isChecked = !list[index].isChecked;
    state = ListService(list);
    _saveList();
  }

  // Удалить строку
  void deleteItem(int index) {
    var list = state.items;
    list.removeAt(index);
    state = ListService(list);
    _saveList();
  }

  // Добавить строку
  void addItem(int index, String name) {
    var list = state.items;
    list.insert(index, ChecklistItem(name: name, isChecked: false));
    state = ListService(list);
    _saveList();
  }

  // Изменить строку
  void updateItemName(int index, String newName) {
    var list = state.items;
    list[index].name = newName;
    state = ListService(list);
    _saveList();
  }

  // Изменить порядок строк
  void reorder(int oldIndex, int newIndex) {
    var list = state.items;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = ListService(list);
    _saveList();
  }
}

class SettingsNotifier extends Notifier<SettingsService> {
  // Флаг, чтобы не загружать дважды
  bool _isLoaded = false;

  @override
  SettingsService build() {
    // Инициализируем начальное состояние
    return const SettingsService(isLoading: true);
  }

  // Метод для загрузки настроек
  Future<void> loadSettings() async {
    // Если уже загружено, не загружаем снова
    if (_isLoaded) return;

    final result = await SettingsService.load();

    if (result is Success) {
      final service = result.data as SettingsService;
      state = service;
    } else {
      // Ошибка загрузки - используем значения по умолчанию
      state = const SettingsService(isLoading: false);
    }
   _isLoaded = true;
  }

  // Приватный метод для сохранения
  Future<void> _saveSettings() async {
    await state.save();
  }

  // Увеличить размер шрифта
  Future<void> incFontSize() async {
    if (state.fontSize < 40) {
      final newSize = state.fontSize + 2;
      // Создаем новый объект и присваиваем его state
      state = state.copyWith(fontSize: newSize);
      await _saveSettings();
    }
  }

  // Уменьшить размер шрифта
  Future<void> decFontSize() async {
    if (state.fontSize > 10) {
      final newSize = state.fontSize - 2;
      state = state.copyWith(fontSize: newSize);
      await _saveSettings();
    }
  }

  // Дополнительный метод для установки размера
  Future<void> setFontSize(double size) async {
    state = state.copyWith(titleFontSize: size.clamp(10.0, 40.0));
    await _saveSettings();
  }

  // Увеличить размер шрифта заголовка
  Future<void> incTitleFontSize() async {
    if (state.titleFontSize < 40) {
      final newSize = state.titleFontSize + 2;
      // Создаем новый объект и присваиваем его state
      state = state.copyWith(titleFontSize: newSize);
      await _saveSettings();
    }
  }

  // Уменьшить размер шрифта заголовка
  Future<void> decTitleFontSize() async {
    if (state.titleFontSize > 10) {
      final newSize = state.titleFontSize - 2;
      state = state.copyWith(titleFontSize: newSize);
      await _saveSettings();
    }
  }

  // Установить размера шрифта заголовка
  Future<void> setTitleFontSize(double size) async {
    state = state.copyWith(titleFontSize: size.clamp(10.0, 40.0));
    await _saveSettings();
  }

  // Установить индекс текущего элемента
  Future<void> setSelectedIndex(int? index) async {
    state = state.copyWith(selectedIndex: index);
    await _saveSettings();
  }

  // Сброс до установок по умолчанию
  Future<void> resetToDefaults() async {
    state = const SettingsService(fontSize: defFontSize, titleFontSize: defTitleFontSize, selectedIndex: defSelectedIndex);
    await _saveSettings();
  }

}
