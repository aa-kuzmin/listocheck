import 'package:yaml/yaml.dart';
import 'package:flutter/foundation.dart';

import 'storage_service.dart';
import 'google_drive_service.dart';
import '../utils/errors.dart';
import '../models/checklist_item.dart';
import '../constants.dart';

class ListService {
  List<ChecklistItem> items;
  final bool isLoading;

  bool _isFromDrive = false;

  ListService(this.items, {this._isFromDrive = false, this.isLoading = false});

  /// Фабричный конструктор, создающий экземпляр [ListService] напрямую из YamlMap.
  factory ListService.fromYaml(YamlMap map, {bool isFromDrive = false}) {
    // Проверяем наличие ключа 'items' и то, что он является списком
    if (!map.containsKey('items') || map['items'] is! YamlList) {
      return ListService([], isFromDrive: isFromDrive);
    }
    
    var list = <ChecklistItem>[];
    for (final dynamic raw in map['items']) {
      if (raw is YamlMap) {
        // Если элемент — YamlMap, передаем её в fromYaml модели ChecklistItem
        list.add(ChecklistItem.fromYaml(raw));
      } else if (raw is String) {
        // Поддержка упрощенного формата списка строк без флага checked
        list.add(ChecklistItem(name: raw, isChecked: false));
      }
    }
    return ListService(list, isFromDrive: isFromDrive, isLoading: false);
  }

  // Загрузка списка из файла
  static Future<Result> load({GoogleDriveService? driveService}) async {
    try {
      // Если есть Google Drive и авторизация, пробуем загрузить оттуда
      if (driveService != null && driveService.isAuthenticated) {
        final driveData = await driveService.syncFromDrive();
        if (driveData['list'] != null && driveData['list']!.isNotEmpty) {
          try {
            final yamlMap = loadYaml(driveData['list']!) as YamlMap;
            return Success(ListService.fromYaml(yamlMap, isFromDrive: true));
          } catch (e) {
            if (kDebugMode) print('Ошибка парсинга списка из Google Drive: $e');
          }
        }
      }
      
      // Если не загрузилось из Drive или Drive недоступен, загружаем локально
      final result = await StorageService.readYamlFile(listFileName);
      if (result is Success && result.data != null && result.data is YamlMap) {
        return Success(ListService.fromYaml(result.data as YamlMap, isFromDrive: false));
      } else {
        return result;
      }
    } catch (e) {
      if (kDebugMode) print('Ошибка загрузки списка: $e');
      return Failure(AppError.errLoadList);
    }
  }

  // Сохранение списка в файл
  Future<Result> save({GoogleDriveService? driveService}) async {
    try {
      final data = {
        'items': items.map((item) => item.toYaml()).toList(),
      };
      final yamlString = StorageService.mapToYaml(data);
      
      // Сохраняем локально всегда
      await StorageService.writeYamlFile(listFileName, data);
      
      // Если есть Google Drive и авторизация, сохраняем туда
      if (driveService != null && driveService.isAuthenticated) {
        final success = await driveService.uploadFile(listFileName, yamlString);
        if (success) {
          if (kDebugMode) print('Список сохранен в Google Drive');
        } else {
          if (kDebugMode) print('Не удалось сохранить список в Google Drive');
        }
      }
      
      return Success(null);
    } catch (e) {
      return Failure(AppError.errSaveList);
    }
  }
}