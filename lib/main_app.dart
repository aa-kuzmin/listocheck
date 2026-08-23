import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/l10n.dart';

import 'screens/home_screen.dart';
import 'services/providers_service.dart';

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _AppState();
}

class _AppState extends ConsumerState<MainApp> {
  @override
  void initState() {
    super.initState();
    // Загружаем данные в фоне
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    // Инициализируем Google Drive при запуске приложения
    _initializeGoogleDrive();
    ref.watch(googleDriveInitializationProvider);
  }

  Future<void> _initializeGoogleDrive() async {
    // Ждем инициализации Google Drive
    await ref.read(googleDriveInitializationProvider.future);
  }

  Future<void> _loadData() async {
    try {
      final settingsNotifier = ref.read(settingsProvider.notifier);
      final settings = ref.read(settingsProvider);
      final listNotifier = ref.read(listProvider.notifier);
      final list = ref.read(listProvider);
      
      await Future.wait([
        settingsNotifier.loadSettings(),
        listNotifier.loadList(),
      ]);
      if (settings.selectedIndex > list.items.length || settings.selectedIndex < 0) {
        settingsNotifier.setSelectedIndex(list.items.length - 1);
      }
    } catch (e) {
      if (kDebugMode) print('Error loading data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Определяем язык системы
    final String systemLanguage = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final Locale locale = Locale(systemLanguage == 'ru' ? 'ru' : 'en');

    return MaterialApp(
      title: locale.languageCode == 'ru' ? 'Листочек' : 'Listocheck',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: true,
      locale: locale,
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
    );
  }
}
