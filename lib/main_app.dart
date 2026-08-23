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
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Загружаем данные после первой отрисовки
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      // Сначала инициализируем Google Drive
      final driveInitResult = await ref.read(googleDriveInitializationProvider.future);
      
      if (kDebugMode) print('Google Drive инициализация: $driveInitResult');
      
      // Затем загружаем настройки и список
      final settingsNotifier = ref.read(settingsProvider.notifier);
      final listNotifier = ref.read(listProvider.notifier);
      
      await Future.wait([
        settingsNotifier.loadSettings(),
        listNotifier.loadList(),
      ]);
      
      // Обновляем выбранный индекс
      final settings = ref.read(settingsProvider);
      final list = ref.read(listProvider);
      
      if (settings.selectedIndex > list.items.length - 1 || settings.selectedIndex < 0) {
        settingsNotifier.setSelectedIndex(list.items.length - 1);
      }
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      if (kDebugMode) print('Error loading data: $e');
      setState(() {
        _isInitialized = true;
      });
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