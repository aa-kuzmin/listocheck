import 'storage_service.dart';
import '../utils/errors.dart';
import '../constants.dart';

class SettingsService {
  double fontSize = 18.0;
  double titleFontSize = 20.0;
  int? selectedIndex = 0;

  final StorageService _storage = StorageService();

  // Загрузка настроек из файла
  Future<Result> load() async {
    try {
      final result = await _storage.readYamlFile(settingsFileName);
      if (result is Success) {
        fontSize = (result.data[fontSizeKey]) ?? 18.0;
        titleFontSize = (result.data[titleFontSizeKey]) ?? 20.0;
        selectedIndex = (result.data[selectedIndexKey]) ?? 0;
      }
      return Success(null);
    } catch (e) {
      return Failure(AppError.errLoadSettings);
    }
  }

  // Сохранение настроек в файл
  Future<Result> save() async {
    Result result = Success(null);
    try {
      final data = {
        fontSizeKey: fontSize,
        titleFontSizeKey: titleFontSize,
        selectedIndexKey: selectedIndex,
      };
      result = await _storage.writeYamlFile(settingsFileName, data);
    } catch (e) {
      return Failure(AppError.errSaveSettings);
    }
    return result;
  }
}
