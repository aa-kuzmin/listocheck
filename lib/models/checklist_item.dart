import 'package:flutter/foundation.dart';

// Класс для хранения одного элемента чеклиста
class ChecklistItem {
  String name;
  bool isChecked;

  ChecklistItem({
    required this.name,
    required this.isChecked,
  });

  Map<String, dynamic> toYaml() {
    return {
      'name': name,
      'is_checked': isChecked,
    };
  }

  factory ChecklistItem.fromYaml(Map<dynamic, dynamic> json) {
    var item = json['name'];

    if (kDebugMode) {
      if (item == Null) print('json[\'name\'] == Null');
      if (item.runtimeType == Null) print('json[\'name\'].runtimeType == Null');
      if (item is String) print('json[\'name\'] is String');
      print('json[\'name\']=[$item (${item.runtimeType})]');
    }

    if (item.runtimeType == Null) item = '';

    return ChecklistItem(
      name: item is String ? item : item.toString(),
      isChecked: json['is_checked'] as bool,
    );
  }
}
