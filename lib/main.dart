import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'utils/system_ui.dart';
import 'main_app.dart';
import 'services/settings_service.dart';
import 'services/providers_service.dart';
import 'services/list_service.dart';
import '../services/google_drive_service.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsService>(() => SettingsNotifier());
final listProvider = NotifierProvider<ListNotifier, ListService>(() => ListNotifier());

final googleDriveServiceProvider = Provider<GoogleDriveService>((ref) => GoogleDriveService());
final googleDriveAuthProvider = StateProvider<bool>((ref) => false);
final googleDriveAccountProvider = StateProvider<String?>((ref) => null);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemUIUtils.configureSystemUI();
  
  // Запускаем приложение с ProviderScope и показываем splash сразу
  runApp(const ProviderScope(child: MainApp()));
}
