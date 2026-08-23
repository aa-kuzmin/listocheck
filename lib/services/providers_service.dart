import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:listocheck/models/checklist_item.dart';

import 'settings_service.dart';
import 'list_service.dart';
import '../constants.dart';
import '../utils/errors.dart';
import 'google_drive_service.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsService>(() => SettingsNotifier());
final listProvider = NotifierProvider<ListNotifier, ListService>(() => ListNotifier());

final googleDriveServiceProvider = Provider<GoogleDriveService>((ref) => GoogleDriveService());
final googleDriveAuthProvider = StateProvider<bool>((ref) => false);
final googleDriveAccountProvider = StateProvider<String?>((ref) => null);


final googleDriveInitializationProvider = FutureProvider<bool>((ref) async {
  final driveService = ref.read(googleDriveServiceProvider);
  final success = await driveService.restoreSession();
  
  if (success) {
    ref.read(googleDriveAuthProvider.notifier).state = true;
    final account = driveService.getCurrentAccount();
    ref.read(googleDriveAccountProvider.notifier).state = account?.email;

    // Если сессия восстановлена, обновляем провайдеры
    final listNotifier = ref.read(listProvider.notifier);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    listNotifier.setDriveService(driveService);
    settingsNotifier.setDriveService(driveService);
    
    // Загружаем данные из Drive
    await listNotifier.loadList();
    await settingsNotifier.loadSettings();

  }
  
  return success;
});

// final googleDriveInitializationProvider = FutureProvider<bool>((ref) async {
//   final driveService = ref.watch(googleDriveServiceProvider);
//   final success = await driveService.restoreSession();
  
//   if (success) {
//     final account = driveService.getCurrentAccount();
//     ref.read(googleDriveAccountProvider.notifier).state = account?.email;
//     ref.read(googleDriveAuthProvider.notifier).state = true;
    
//     // Если сессия восстановлена, обновляем провайдеры
//     final listNotifier = ref.read(listProvider.notifier);
//     final settingsNotifier = ref.read(settingsProvider.notifier);
//     listNotifier.setDriveService(driveService);
//     settingsNotifier.setDriveService(driveService);
    
//     // Загружаем данные из Drive
//     await listNotifier.loadList();
//     await settingsNotifier.loadSettings();
//   }
  
//   return success;
// });

class ListNotifier extends Notifier<ListService> {
  bool _isLoaded = false;
  GoogleDriveService? _driveService;

  @override
  ListService build() {
    // Инициализируем начальное состояние
    return ListService([]);
  }

  void setDriveService(GoogleDriveService? service) {
    _driveService = service;
  }

  Future<void> loadList({bool force = false}) async {
    if (_isLoaded && !force) return;
    
    final result = await ListService.load(driveService: _driveService);
    if (result is Success) {
      final service = result.data ?? ListService([]);
      state = service;
    } else {
      state = ListService([]);
    }
    _isLoaded = true;
  }

  // Приватный метод для сохранения
  Future<void> _saveList() async {
    await state.save(driveService: _driveService);
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
  
  GoogleDriveService? _driveService;

  @override
  SettingsService build() {
    // Инициализируем начальное состояние
    return const SettingsService(isLoading: true);
  }

  void setDriveService(GoogleDriveService? service) {
    _driveService = service;
  }

  // Метод для загрузки настроек
  Future<void> loadSettings({bool force = false}) async {
    if (_isLoaded && !force) return;
    
    final result = await SettingsService.load(driveService: _driveService);
    if (result is Success) {
      final service = result.data as SettingsService;
      state = service;
    } else {
      state = const SettingsService(isLoading: false);
    }
    _isLoaded = true;
  }

  // Приватный метод для сохранения
  Future<void> _saveSettings() async {
    await state.save(driveService: _driveService);
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
