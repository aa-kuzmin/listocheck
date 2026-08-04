import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:yaml/yaml.dart';
import '../l10n/generated/app_localizations.dart';
import '../utils/errors.dart';

class StorageService {
  // Получение пути к директории приложения
  Future<Directory> _getAppDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  // Получение полного пути к файлу
  Future<String> _getFilePath(String fileName) async {
    final dir = await _getAppDirectory();
    return '${dir.path}/$fileName';
  }

  // Чтение YAML из файла
  Future<Result<Map<dynamic, dynamic>?>?> readYamlFile(String fileName) async {
    try {
      final filePath = await _getFilePath(fileName);
      final file = File(filePath);
      
      if (await file.exists()) {
        final contents = await file.readAsString();
        return Success(loadYaml(contents) as Map<dynamic, dynamic>?);
      }
      return null;
    } catch (e) {
      //_showErrorMessage(localizations?.errLoadSettings ?? 'Error loading settings');
      return null;
    }
  }

  // Запись YAML в файл
  Future<Result> writeYamlFile(String fileName, Map<String, dynamic> data) async {
    final AppLocalizations? localizations = AppLocalizations.of(context);
    try {
      final filePath = await _getFilePath(fileName);
      final file = File(filePath);
      
      // Преобразуем Map в YAML строку вручную
      String yamlString = _mapToYaml(data);
      await file.writeAsString(yamlString);
    } catch (e) {
      return Result.errLoadSettings;
      //_showErrorMessage(localizations?.errSaveSettings ?? 'Error saving settings');
    }
    return Result.Success;
  }

  // Преобразование Map в YAML строку
  String _mapToYaml(Map<String, dynamic> data, {int indent = 0}) {
    final buffer = StringBuffer();
    final indentStr = '  ' * indent;
    
    data.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        buffer.writeln('$indentStr$key:');
        buffer.write(_mapToYaml(value, indent: indent + 1));
      } else if (value is List) {
        buffer.writeln('$indentStr$key:');
        for (var item in value) {
          if (item is Map<String, dynamic>) {
            buffer.write('$indentStr  - ');
            // Для списка объектов с одним полем
            if (item.length == 1) {
              final entry = item.entries.first;
              if (entry.value is String) {
                buffer.writeln('${entry.key}: ${_escapeYamlString(entry.value)}');
              } else {
                buffer.writeln('${entry.key}: $entry.value');
              }
            } else {
              buffer.writeln();
              buffer.write(_mapToYaml(item, indent: indent + 2));
            }
          } else if (item is String) {
            buffer.writeln('$indentStr  - ${_escapeYamlString(item)}');
          } else {
            buffer.writeln('$indentStr  - $item');
          }
        }
      } else if (value is String) {
        buffer.writeln('$indentStr$key: ${_escapeYamlString(value)}');
      } else {
        buffer.writeln('$indentStr$key: $value');
      }
    });
    
    return buffer.toString();
  }

  // Экранирование строк для YAML
  String _escapeYamlString(String value) {
    if (value.contains(':') || value.contains('#') || value.contains('\n')) {
      return '"$value"';
    }
    return value;
  }
}
