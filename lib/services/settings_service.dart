import 'package:flutter/foundation.dart';
import 'package:yaml/yaml.dart';

import 'storage_service.dart';
import 'google_drive_service.dart';
import '../utils/errors.dart';
import '../constants.dart';

/* class TempSettingsService {
  final bool isFabVisible;

  const TempSettingsService({this.isFabVisible = false});

  TempSettingsService copyWith({bool? isFabVisible}) {
    bool? isFabVisible;
    return TempSettingsService(isFabVisible: isFabVisible ?? this.isFabVisible);
  }
} */

class SettingsService {
  final double fontSize;
  final double titleFontSize;
  final int selectedIndex;
  final bool isLoading;

  const SettingsService({this.fontSize = defFontSize, this.titleFontSize = defTitleFontSize, this.selectedIndex = defSelectedIndex, this.isLoading = true});

  SettingsService copyWith({
    double? fontSize,
    double? titleFontSize,
    int? selectedIndex,
    bool? isLoading,
    })
  {
    return SettingsService(
      fontSize: fontSize ?? this.fontSize,
      titleFontSize: titleFontSize ?? this.titleFontSize,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  // Преобразование в Map для сохранения
  Map<String, dynamic> toMap() {
    return {
      fontSizeKey: fontSize,
      titleFontSizeKey: titleFontSize,
      selectedIndexKey: selectedIndex,
    };
  }

  // Загрузка настроек из файла.
  static Future<Result> load({GoogleDriveService? driveService}) async {
    try {
      // Если есть Google Drive и авторизация, пробуем загрузить оттуда
      if (driveService != null && driveService.isAuthenticated) {
        final driveData = await driveService.syncFromDrive();
        if (driveData['settings'] != null && driveData['settings']!.isNotEmpty) {
          try {
            final yamlMap = loadYaml(driveData['settings']!) as Map;
            final settings = SettingsService(
              fontSize: (yamlMap[fontSizeKey] ?? defFontSize).toDouble(),
              titleFontSize: (yamlMap[titleFontSizeKey] ?? defTitleFontSize).toDouble(),
              selectedIndex: yamlMap[selectedIndexKey] ?? defSelectedIndex,
              isLoading: false,
            );
            return Success(settings);
          } catch (e) {
            if (kDebugMode) print('Ошибка парсинга настроек из Google Drive: $e');
          }
        }
      }

      // Если не загрузилось из Drive или Drive недоступен, загружаем локально
      final result = await StorageService.readYamlFile(settingsFileName);
      
      if (result is Success) {
        final data = result.data as Map?;
        if (data != null && data.isNotEmpty) {
          return Success(SettingsService(
            fontSize: (data[fontSizeKey] ?? defFontSize).toDouble(),
            titleFontSize: (data[titleFontSizeKey] ?? defTitleFontSize).toDouble(),
            selectedIndex: data[selectedIndexKey] ?? defSelectedIndex,
            isLoading: false,
          ));
        }
      }
      
      // Если файл не найден или поврежден, возвращаем настройки по умолчанию
      return Success(const SettingsService(isLoading: false));
      
    } catch (e) {
      if (kDebugMode) print('Ошибка загрузки настроек: $e');
      return Success(const SettingsService(isLoading: false));
    }
  }

  // Сохранение настроек в файл
  Future<Result> save({GoogleDriveService? driveService}) async {
    try {
      final data = toMap();
      
      // Сохраняем локально всегда
      await StorageService.writeYamlFile(settingsFileName, data);
      
      // Если есть Google Drive и авторизация, сохраняем туда
      if (driveService != null && driveService.isAuthenticated) {
        // Преобразуем Map в YAML строку
        final yamlString = StorageService.mapToYaml(data);
        final success = await driveService.uploadFile('settings.yaml', yamlString);
        if (success) {
          if (kDebugMode) print('Настройки сохранены в Google Drive');
        } else {
          if (kDebugMode) print('Не удалось сохранить настройки в Google Drive');
        }
      }
      
      return Success(null);
    } catch (e) {
      if (kDebugMode) print('Ошибка сохранения настроек: $e');
      return Failure(AppError.errSaveSettings);
    }
  }
}
