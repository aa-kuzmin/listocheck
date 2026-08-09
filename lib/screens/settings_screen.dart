import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsService _settings;
  const SettingsScreen({super.key, required this._settings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState(settings: _settings);
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settings;

  _SettingsScreenState({required this._settings});

  // Увеличение шрифта элементов
  void _increaseFontSize() {
    setState(() {
      _settings.fontSize = (_settings.fontSize + 2.0).clamp(10.0, 40.0);
    });
    _settings.save();
  }

  // Уменьшение шрифта элементов
  void _decreaseFontSize() {
    setState(() {
      _settings.fontSize = (_settings.fontSize - 2.0).clamp(10.0, 40.0);
    });
    _settings.save();
  }

  // Увеличение шрифта заголовка
  void _increaseTitleFontSize() {
    setState(() {
      _settings.titleFontSize = (_settings.titleFontSize + 2.0).clamp(20.0, 40.0);
    });
    _settings.save();
  }

  // Уменьшение шрифта заголовка
  void _decreaseTitleFontSize() {
    setState(() {
      _settings.titleFontSize = (_settings.titleFontSize - 2.0).clamp(20.0, 40.0);
    });
    _settings.save();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const SizedBox(height: 24),
          Text(
            localizations.fontSettings,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          
          // Настройка шрифта элементов списка
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.itemFont,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 40),
                      onPressed: _settings.fontSize > 10 ? _decreaseFontSize : null,
                      tooltip: localizations.decrease,
                    ),
                    const SizedBox(width: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_settings.fontSize.toInt()}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 40),
                      onPressed: _settings.fontSize < 40 ? _increaseFontSize : null,
                      tooltip: localizations.increase,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '${localizations.fontSize}: ${_settings.fontSize.toInt()} px',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    localizations.exampleText,
                    style: TextStyle(
                      fontSize: _settings.fontSize,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Настройка шрифта заголовка
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.titleFont,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 40),
                      onPressed: _settings.titleFontSize > 20 ? _decreaseTitleFontSize : null,
                      tooltip: localizations.decrease,
                    ),
                    const SizedBox(width: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_settings.titleFontSize.toInt()}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 40),
                      onPressed: _settings.titleFontSize < 40 ? _increaseTitleFontSize : null,
                      tooltip: localizations.increase,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '${localizations.fontSize}: ${_settings.titleFontSize.toInt()} px',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    localizations.exampleTitle,
                    style: TextStyle(
                      fontSize: _settings.titleFontSize,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

  }
}
