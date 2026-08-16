import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'utils/system_ui.dart';
import 'main_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemUIUtils.configureSystemUI();
  
  // Запускаем приложение с ProviderScope и показываем splash сразу
  runApp(const ProviderScope(child: MainApp()));
}
