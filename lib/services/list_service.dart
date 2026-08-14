import 'package:yaml/yaml.dart';
import 'package:flutter/foundation.dart';

import 'storage_service.dart';
import '../utils/errors.dart';
import '../models/checklist_item.dart';
import '../constants.dart';

class ListService {
  List<ChecklistItem> items;

  ListService(this.items);

  /// Фабричный конструктор, создающий экземпляр [ListService] напрямую из YamlMap.
  factory ListService.fromYaml(YamlMap map) {
    // Проверяем наличие ключа 'items' и то, что он является списком
    if (!map.containsKey('items') || map['items'] is! YamlList) {
      return ListService([]);
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
    return ListService(list);
  }

  // Загрузка списка из файла (статический метод)
  static Future<Result> load() async {
    try {
      final result = await StorageService.readYamlFile(listFileName);

      if (result is Success && result.data != null && result.data is YamlMap) {
        // Используем новый фабричный конструктор вместо ручного парсинга здесь
        return Success(ListService.fromYaml(result.data as YamlMap));
      } else {
        return result;
      }
    } catch (e) {
      if (kDebugMode) print('Логируем ошибку: $e');
      return Failure(AppError.errLoadList);
    }
  }

  // Сохранение списка в файл
  Future<Result> save() async {
    try {
      final data = {
        'items': items.map((item) => item.toYaml()).toList(),
      };
      await StorageService.writeYamlFile(listFileName, data);
      return Success(null);
    } catch (e) {
      return Failure(AppError.errSaveList);
    }
  }
}