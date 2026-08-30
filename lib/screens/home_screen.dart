import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'google_account_screen.dart';
import 'settings_screen.dart';
import 'list_screen.dart';
import 'about_screen.dart';
import 'loading_screen.dart';
import '../services/providers_service.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentPageIndex = 0;
  final GlobalKey<ListScreenState> _listScreenKey = GlobalKey<ListScreenState>();

  @override
  void initState() {
    super.initState();
  }

  // Показать информационное сообщение
  void _showInfoMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    }
  }

  // Добавление новой пустой строки
  void _addEmptyItem() {
    final state = _listScreenKey.currentState;
    if (state != null) {
      state.addNewEmptyItem();
    }

  }

  // Снять пометки у всего списка
  void _uncheckAllItems() {
    final localizations = AppLocalizations.of(context)!;
    final listNotifier = ref.read(listProvider.notifier);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations.uncheckAll),
          content: Text(localizations.uncheckAllConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.cancel),
            ),
            ElevatedButton(
              onPressed: () =>
                setState(() {
                  listNotifier.uncheckAllItems();
                  Navigator.pop(context);
                  _showInfoMessage(localizations.uncheckedAll);
                }),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: Text(localizations.uncheck),
            ),
          ],
        );
      },
    );
  }

  // Очистка всего списка
  void _clearAllItems() {
    final localizations = AppLocalizations.of(context)!;
    final listNotifier = ref.read(listProvider.notifier);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations.clearAll),
          content: Text(localizations.clearAllConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  listNotifier.clear();
                  settingsNotifier.setSelectedIndex(-1);
                });
                Navigator.pop(context);
                _showInfoMessage(localizations.listCleared);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: Text(localizations.clear),
            ),
          ],
        );
      },
    );
  }

  // Получение текущей страницы
  Widget _getCurrentPage() {
    final settings = ref.watch(settingsProvider);
    final list = ref.watch(listProvider);

    if (settings.isLoading || list.isLoading) return SafeArea(child: LoadingScreen());
    
    switch (_currentPageIndex) {
      case 0:
        return SafeArea(
          child: ListScreen(
            key: _listScreenKey,
          ),
        );
      case 1:
        return SafeArea(child: SettingsScreen());
      case 2:
        return SafeArea(child: GoogleAccountScreen());
      case 3:
        return SafeArea(child: AboutScreen());
      default:
        return SafeArea(child: ListScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final list = ref.watch(listProvider);
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white,
        systemNavigationBarDividerColor: Colors.grey,
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        appBar: AppBar(
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                tooltip: localizations.openMenu,
              );
            },
          ),
          title: Text(
            _currentPageIndex == 0 && list.items.isNotEmpty ? localizations.list : '',
            style: TextStyle(
              fontSize: settings.titleFontSize,
            ),
          ),
          actions: [
            if (_currentPageIndex == 0 && list.items.isNotEmpty) ...[
              IconButton(
                icon: const Icon(Icons.check_box_outline_blank),
                onPressed: _uncheckAllItems,
                tooltip: localizations.uncheckAllTooltip,
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep, color: Colors.red),
                onPressed: list.items.isEmpty ? null : _clearAllItems,
                tooltip: localizations.clearAllTooltip,
              ),
            ],
          ],
        ),
        drawer: Drawer(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      DrawerHeader(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              localizations.appTitle,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              localizations.appDescription,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.list, color: Colors.blue),
                        title: Text(localizations.list),
                        selected: _currentPageIndex == 0,
                        selectedTileColor: Colors.blue.shade50,
                        onTap: () {
                          setState(() {
                            _currentPageIndex = 0;
                          });
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.settings, color: Colors.green),
                        title: Text(localizations.settings),
                        selected: _currentPageIndex == 1,
                        selectedTileColor: Colors.blue.shade50,
                        onTap: () {
                          setState(() {
                            _currentPageIndex = 1;
                          });
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.cloud, color: Colors.blue),
                        title: Text(localizations.sync),
                        selected: _currentPageIndex == 2,
                        selectedTileColor: Colors.blue.shade50,
                        onTap: () {
                          setState(() {
                            _currentPageIndex = 2;
                          });
                          Navigator.pop(context);
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.info_outline, color: Colors.orange),
                        title: Text(localizations.aboutApp),
                        selected: _currentPageIndex == 3,
                        selectedTileColor: Colors.blue.shade50,
                        onTap: () {
                          setState(() {
                            _currentPageIndex = 3;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
        body: _getCurrentPage(),
        floatingActionButton: _currentPageIndex == 0 && !settings.isLoading && !list.isLoading
            ? Opacity(
                opacity: 0.6,
                child: FloatingActionButton(
                  tooltip: localizations.addItem,
                  onPressed: _addEmptyItem,
                  child: const Icon(Icons.add),
                ),
              )
            : null,
      )
    );
  }
}