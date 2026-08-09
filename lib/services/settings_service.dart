import 'storage_service.dart';

import '../utils/errors.dart';
import '../constants.dart';

class SettingsService {
  final double fontSize;
  final double titleFontSize;
  final int? selectedIndex;
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

  // Загрузка настроек из файла.
  static Future<Result> load() async {
    try {
      final result = await StorageService.readYamlFile(settingsFileName);
      if (result is Success) {
        final data = SettingsService(
          fontSize : (result.data[fontSizeKey]) ?? defFontSize,
          titleFontSize : (result.data[titleFontSizeKey]) ?? defTitleFontSize,
          selectedIndex : (result.data[selectedIndexKey]) ?? defSelectedIndex,
          isLoading: false
        );
        return Success(data);
      } else {
        return Failure(AppError.errLoadSettings);
      }
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
      result = await StorageService.writeYamlFile(settingsFileName, data);
    } catch (e) {
      return Failure(AppError.errSaveSettings);
    }
    return result;
  }
}
