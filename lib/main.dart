import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'utils/system_ui.dart';
import 'main_app.dart';
import 'services/settings_service.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsService>(() => SettingsNotifier());

void main() {

  WidgetsFlutterBinding.ensureInitialized();

  SystemUIUtils.configureSystemUI();

  runApp(const ProviderScope(child: MainApp()));
}


