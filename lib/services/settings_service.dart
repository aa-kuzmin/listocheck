import 'storage_service.dart';
import '../l10n/generated/app_localizations.dart';


class SettingsService {
  final StorageService _storage = StorageService();
  static const String _settingsFileName = 'settings.yaml';
  static const String _fontSizeKey = 'font_size';
  static const String _titleFontSizeKey = 'title_font_size';
  static const String _selectedIndexKey = 'selected_index';
  double fontSize = 18.0;
  double titleFontSize = 20.0;
  int? selectedIndex;

  // Загрузка настроек из файла
  Future<void> load() async {
    final AppLocalizations? localizations = AppLocalizations.of(context);
    try {
      final data = await _storage.readYamlFile(_settingsFileName);
      if (data != null) {
        setState(() {
          fontSize = (data[_fontSizeKey] as double?) ?? 18.0;
          titleFontSize = (data[_titleFontSizeKey] as double?) ?? 20.0;
          selectedIndex = data[_selectedIndexKey];
        });
      }
    } catch (e) {
      _showErrorMessage(localizations?.errLoadSettings ?? 'Error loading settings');
    }
  }

  // Сохранение настроек в файл
  Future<void> save() async {
    final AppLocalizations? localizations = AppLocalizations.of(context);
    try {
      final data = {
        _fontSizeKey: fontSize,
        _titleFontSizeKey: titleFontSize,
        _selectedIndexKey: selectedIndex,
      };
      await _storage.writeYamlFile(_settingsFileName, data);
    } catch (e) {
      _showErrorMessage(localizations?.errSaveSettings ?? 'Error saving settings');
    }
  }
}
