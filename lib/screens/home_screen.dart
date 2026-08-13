import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/checklist_item.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'list_screen.dart';
import 'about_screen.dart';
import '../main.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _isLoading = true;
  int _currentPageIndex = 0;

  // Локальное состояние для отслеживания позиции скролла и видимости FAB
  double _lastScrollOffset = 0.0;
  bool _isFabVisible = true;

  @override
  void initState() {
    super.initState();
    // Загружаем данные после того, как дерево виджетов построено
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });  
  }

  // Загрузка всех данных
  Future<void> _loadAllData() async {
    final notifierSettings = ref.read(settingsProvider.notifier);
    final notifierList = ref.read(listProvider.notifier);

    await notifierSettings.loadSettings();
    await notifierList.loadList();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Показать сообщение об ошибке
/*   void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $message'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
 */

  // Показать информационное сообщение
  void _showInfoMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ℹ️ $message'),
          backgroundColor: Colors.blue.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Добавление новой строки
  void _addItem(String name) {
    final settings = ref.watch(settingsProvider);
    final list = ref.watch(listProvider);
    final listNotifier = ref.read(listProvider.notifier);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    setState(() {
      if (settings.selectedIndex != null && settings.selectedIndex! < list.items.length) {
        listNotifier.addItem(settings.selectedIndex! + 1, ChecklistItem(name: name, isChecked: false));
        settingsNotifier.setSelectedIndex(settings.selectedIndex! + 1);
      } else {
        listNotifier.addItem(list.items.length, ChecklistItem(name: name, isChecked: false));
        settingsNotifier.setSelectedIndex(list.items.length - 1);
      }
    });
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
                  settingsNotifier.setSelectedIndex(null);
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

  // Диалог добавления строки
  void _showAddItemDialog() {
    final TextEditingController controller = TextEditingController();
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations.addItem),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: localizations.enterItem,
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            onSubmitted: (value) {
              final name = value.trim();
              if (name.isNotEmpty) {
                _addItem(name);
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  _addItem(name);
                  Navigator.pop(context);
                }
              },
              child: Text(localizations.add),
            ),
          ],
        );
      },
    );
  }

  // Получение текущей страницы
  Widget _getCurrentPage() {
    switch (_currentPageIndex) {
      case 0:
        return SafeArea(child: ListScreen());
      case 1:
        return SafeArea(child: SettingsScreen());
      case 2:
        return SafeArea(child: ProfileScreen());
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
          leading: _isLoading ? null : Builder(
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
            // Показываем кнопки только на странице списка
            // и если список не пустой
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
                leading: const Icon(Icons.person, color: Colors.purple),
                title: Text(localizations.profile),
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
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(localizations.loadingSettings),
                  ],
                ),
              )
            : NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification notification) {
                  if (notification is ScrollUpdateNotification && _currentPageIndex == 0) {
                    final currentOffset = notification.metrics.pixels;
                    
                    // Порог чувствительности, чтобы избежать дрожания у самого верха
                    if ((currentOffset - _lastScrollOffset).abs() > 5) {
                      if (currentOffset > _lastScrollOffset) {
                        // Пользователь листает вниз — прячем кнопку
                        if (_isFabVisible) {
                          setState(() {
                            _isFabVisible = false;
                          });
                        }
                      } else if (currentOffset < _lastScrollOffset) {
                        // Пользователь листает вверх — показываем кнопку
                        if (!_isFabVisible) {
                          setState(() {
                            _isFabVisible = true;
                          });
                        }
                      }
                      _lastScrollOffset = currentOffset;
                    }
                  }
                  return false; // Передаем событие дальше, чтобы ReorderableListView работал
                },
                child: _getCurrentPage(),
              ),
        floatingActionButton: _currentPageIndex == 0 && !_isLoading && _isFabVisible
            ? FloatingActionButton(
                tooltip: localizations.addItem,
                onPressed: _showAddItemDialog,
                child: const Icon(Icons.add),
              )
            : null,
      )
    );
  }
}
