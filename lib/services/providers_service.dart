import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_service.dart';
import '../constants.dart';
import '../utils/errors.dart';

class IsLoadingNotifier extends Notifier<bool> {
  @override
  bool build() {
    // Инициализируем начальное состояние
    return true;
  }
  
  void turn() => state = !state;
  void finish() => state = false;
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

  Future<void> incFontSize() async {
    if (state.fontSize < 40) {
      final newSize = state.fontSize + 2;
      // Создаем новый объект и присваиваем его state
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

  // Дополнительный метод для установки размера
  Future<void> setFontSize(double size) async {
    state = state.copyWith(titleFontSize: size.clamp(10.0, 40.0));
    await _saveSettings();
  }

  Future<void> incTitleFontSize() async {
    if (state.titleFontSize < 40) {
      final newSize = state.titleFontSize + 2;
      // Создаем новый объект и присваиваем его state
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

  // Дополнительный метод для установки размера
  Future<void> setTitleFontSize(double size) async {
    state = state.copyWith(titleFontSize: size.clamp(10.0, 40.0));
    await _saveSettings();
  }

  // Метод для сброса
  Future<void> resetToDefaults() async {
    state = const SettingsService(fontSize: defFontSize, titleFontSize: defTitleFontSize, selectedIndex: defSelectedIndex);
    await _saveSettings();
  }

}
