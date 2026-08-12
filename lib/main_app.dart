import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'screens/home_screen.dart';


class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _AppState();

}

class _AppState extends State<MainApp> {
  Locale _locale = const Locale('ru');
  bool _isLocaleLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    try {
      // Получаем язык системы Android
      final String systemLanguage = WidgetsBinding.instance.platformDispatcher.locale.languageCode;

      // Определяем язык приложения
      String languageCode;
      if (systemLanguage == 'ru') {
        languageCode = 'ru';
      } else {
        languageCode = 'en';
      }
      
      if (mounted) {  // ← Проверяем, что виджет еще существует
        setState(() {
          _locale = Locale(languageCode);
          _isLocaleLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {  // ← Проверяем, что виджет еще существует
        setState(() {
          _locale = const Locale('en');
          _isLocaleLoaded = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocaleLoaded) {
      return const MaterialApp(
        home: Scaffold(
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading locale...'),
            ],
          ),
        ),
        debugShowCheckedModeBanner: false,
      );
    }

    return MaterialApp(
      title: _locale.languageCode == 'ru' ? 'Листочек' : 'Listocheck',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
      locale: _locale,
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
    );
  }
}
