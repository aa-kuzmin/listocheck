import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'utils/system_ui.dart';
import 'main_app.dart';
import 'services/settings_service.dart';
import 'services/providers_service.dart';
import 'services/list_service.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsService>(() => SettingsNotifier());
final listProvider = NotifierProvider<ListNotifier, ListService>(() => ListNotifier());

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemUIUtils.configureSystemUI();

  // Показываем splash-экран пока загружается приложение
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.list_alt,
                size: 80,
                color: Colors.blue,
              ),
              SizedBox(height: 16),
              CircularProgressIndicator(
                color: Colors.blue,
              ),
            ],
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    ),
  );
  
  // Загружаем данные и переключаемся на основное приложение
  Future.microtask(() {
    // Здесь можно предзагрузить данные
    runApp(const ProviderScope(child: MainApp()));
  });
}