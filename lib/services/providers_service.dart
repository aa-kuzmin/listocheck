import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:listocheck/models/checklist_item.dart';
import 'package:flutter/foundation.dart';

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
  try {
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
      
      // Загружаем данные из Drive только если есть файлы
      try {
        final hasData = await driveService.hasDataInDrive();
        if (hasData) {
          await listNotifier.loadList(force: true);
          await settingsNotifier.loadSettings(force: true);
        }
      } catch (e) {
        if (kDebugMode) print('Ошибка загрузки данных из Drive: $e');
        // Не критично, продолжаем с локальными данными
      }
    }
    
    return success;
  } catch (e) {
    if (kDebugMode) print('Ошибка инициализации Google Drive: $e');
    return false;
  }
});

class ListNotifier extends Notifier<ListService> {
  bool _isLoaded = false;
  GoogleDriveService? _driveService;
  bool _isLoading = false;

  @override
  ListService build() {
    return ListService([]);
  }

  void setDriveService(GoogleDriveService? service) {
    _driveService = service;
  }

  Future<void> loadList({bool force = false}) async {
    if (_isLoaded && !force) return;
    if (_isLoading) return;
    
    _isLoading = true;
    try {
      final result = await ListService.load(driveService: _driveService);
      if (result is Success) {
        final service = result.data ?? ListService([]);
        state = service;
      } else {
        state = ListService([]);
      }
      _isLoaded = true;
    } catch (e) {
      if (kDebugMode) print('Ошибка загрузки списка: $e');
      state = ListService([]);
    } finally {
      _isLoading = false;
    }
  }

  // Приватный метод для сохранения
  Future<void> _saveList() async {
    try {
      await state.save(driveService: _driveService);
    } catch (e) {
      if (kDebugMode) print('Ошибка сохранения списка: $e');
    }
  }

  // Остальные методы без изменений
  void clear() {
    state = ListService([]);
    _saveList();
  }

  void uncheckAllItems() {
    var list = state.items;
    for (var item in list) {
      item.isChecked = false;
    }
    state = ListService(list);
    _saveList();
  }

  void toggleItem(int index) {
    var list = state.items;
    list[index].isChecked = !list[index].isChecked;
    state = ListService(list);
    _saveList();
  }

  void deleteItem(int index) {
    var list = state.items;
    list.removeAt(index);
    state = ListService(list);
    _saveList();
  }

  void addItem(int index, String name) {
    var list = state.items;
    list.insert(index, ChecklistItem(name: name, isChecked: false));
    state = ListService(list);
    _saveList();
  }

  void updateItemName(int index, String newName) {
    var list = state.items;
    list[index].name = newName;
    state = ListService(list);
    _saveList();
  }

  void reorder(int oldIndex, int newIndex) {
    var list = state.items;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = ListService(list);
    _saveList();
  }
}

class SettingsNotifier extends Notifier<SettingsService> {
  bool _isLoaded = false;
  GoogleDriveService? _driveService;
  bool _isLoading = false;

  @override
  SettingsService build() {
    return const SettingsService(isLoading: true);
  }

  void setDriveService(GoogleDriveService? service) {
    _driveService = service;
  }

  Future<void> loadSettings({bool force = false}) async {
    if (_isLoaded && !force) return;
    if (_isLoading) return;
    
    _isLoading = true;
    try {
      final result = await SettingsService.load(driveService: _driveService);
      if (result is Success) {
        final service = result.data as SettingsService;
        state = service;
      } else {
        state = const SettingsService(isLoading: false);
      }
      _isLoaded = true;
    } catch (e) {
      if (kDebugMode) print('Ошибка загрузки настроек: $e');
      state = const SettingsService(isLoading: false);
    } finally {
      _isLoading = false;
    }
  }

  // Приватный метод для сохранения
  Future<void> _saveSettings() async {
    try {
      await state.save(driveService: _driveService);
    } catch (e) {
      if (kDebugMode) print('Ошибка сохранения настроек: $e');
    }
  }

  // Остальные методы без изменений
  Future<void> incFontSize() async {
    if (state.fontSize < 40) {
      final newSize = state.fontSize + 2;
      state = state.copyWith(fontSize: newSize);
      await _saveSettings();
    }
  }

  Future<void> decFontSize() async {
    if (state.fontSize > 10) {
      final newSize = state.fontSize - 2;
      state = state.copyWith(fontSize: newSize);
      await _saveSettings();
    }
  }

  Future<void> setFontSize(double size) async {
    state = state.copyWith(titleFontSize: size.clamp(10.0, 40.0));
    await _saveSettings();
  }

  Future<void> incTitleFontSize() async {
    if (state.titleFontSize < 40) {
      final newSize = state.titleFontSize + 2;
      state = state.copyWith(titleFontSize: newSize);
      await _saveSettings();
    }
  }

  Future<void> decTitleFontSize() async {
    if (state.titleFontSize > 10) {
      final newSize = state.titleFontSize - 2;
      state = state.copyWith(titleFontSize: newSize);
      await _saveSettings();
    }
  }

  Future<void> setTitleFontSize(double size) async {
    state = state.copyWith(titleFontSize: size.clamp(10.0, 40.0));
    await _saveSettings();
  }

  Future<void> setSelectedIndex(int? index) async {
    state = state.copyWith(selectedIndex: index);
    await _saveSettings();
  }

  Future<void> resetToDefaults() async {
    state = const SettingsService(fontSize: defFontSize, titleFontSize: defTitleFontSize, selectedIndex: defSelectedIndex);
    await _saveSettings();
  }
}