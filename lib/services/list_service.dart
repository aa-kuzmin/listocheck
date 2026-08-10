import 'storage_service.dart';
import '../utils/errors.dart';
import '../models/checklist_item.dart';
import '../constants.dart';

class ListService {
  final List<ChecklistItem> items;

  const ListService(this.items);

  // Загрузка списка из файла
  static Future<Result> load() async {
    try {
      final result = await StorageService.readYamlFile(listFileName);
      
      if (result is Success && result.data != null && result.data['items'] is List) {
        final List<dynamic> decodedList = result.data['items'] as List;
        final list = decodedList.map((item) {
            if (item is Map) {
              return ChecklistItem.fromYaml(item);
            }
            return ChecklistItem(name: item.toString(), isChecked: false);
          }).toList();
        return Success(list);
      } else {
        return result;
      }
    } catch (e) {
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
