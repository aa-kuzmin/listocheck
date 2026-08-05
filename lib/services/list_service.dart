import 'storage_service.dart';
import '../utils/errors.dart';
import '../models/checklist_item.dart';
import '../constants.dart';

class ListService {
  List<ChecklistItem> items = [];
  final StorageService _storage = StorageService();

  // Загрузка списка из файла
  Future<Result> load() async {
    try {
      final result = await _storage.readYamlFile(itemsFileName);
      
      if (result is Success && result.data != null && result.data['items'] is List) {
        final List<dynamic> decodedList = result.data['items'] as List;
        items = decodedList.map((item) {
            if (item is Map) {
              return ChecklistItem.fromYaml(item);
            }
            return ChecklistItem(name: item.toString(), isChecked: false);
          }).toList();
        return Success(items);
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
      await _storage.writeYamlFile(itemsFileName, data);
      return Success(null);
    } catch (e) {
      return Failure(AppError.errSaveList);
    }
  }
}
