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

  runApp(const ProviderScope(child: MainApp()));
}
