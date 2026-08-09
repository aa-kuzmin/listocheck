import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/checklist_item.dart';
import '../services/settings_service.dart';
import '../services/list_service.dart';
import '../utils/errors.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'list_screen.dart';
import '../services/providers_service.dart';


class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {

  int _currentPageIndex = 0;

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
    final localizations = AppLocalizations.of(context)!;

    var result = await settings.load();
    if (result is Failure) {
      _showErrorMessage(localizations.errLoadSettings);
    } else {
      if (result is Success && result.data != null) {
        setState((){});
      }
    }

    result = await list.load();
    if (result is Failure) {
      _showErrorMessage(localizations.errLoadList);
    } else {
      if (result is Success && result.data != null) {
        setState((){});
      }
    }

    if (mounted) {
      ref.read(isLoadingProvider.notifier).finish();
    };
    }

  }

  // Показать сообщение об ошибке
  void _showErrorMessage(String message) {
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

  // Показать информационное сообщение
  void _showInfoMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ℹ️ $message'),
          backgroundColor: Colors.blue.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Добавление новой строки
  void _addItem(String name) {
    setState(() {
      if (settings.selectedIndex != null && settings.selectedIndex! < list.items.length) {
        list.items.insert(settings.selectedIndex! + 1, ChecklistItem(name: name, isChecked: false));
        settings.selectedIndex = settings.selectedIndex! + 1;
      } else {
        list.items.add(ChecklistItem(name: name, isChecked: false));
        settings.selectedIndex = list.items.length - 1;
      }
    });
    list.save();
    settings.save();
  }

  // Снять пометки у всего списка
  void _uncheckAllItems() {
    final localizations = AppLocalizations.of(context)!;
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
              onPressed: () {
                setState(() {
                  for (var item in list.items) {
                    item.isChecked = false;
                  }
                });
                list.save();
                Navigator.pop(context);
                _showInfoMessage(localizations.uncheckedAll);
              },
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
                  list.items.clear();
                  settings.selectedIndex = null;
                });
                list.save();
                settings.save();
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
        return SafeArea(child: SettingsScreen(settings: settings));
      case 2:
        return SafeArea(child: ProfileScreen());
      default:
        return SafeArea(child: ListScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
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
            _currentPageIndex == 0 ? localizations.list : '',
            style: TextStyle(
              fontSize: settings.titleFontSize,
            ),
          ),
          actions: [
            // Показываем кнопки только на странице списка
            if (_currentPageIndex == 0) ...[
              IconButton(
                icon: const Icon(Icons.check_box_outline_blank),
                onPressed: list.items.isEmpty ? null : _uncheckAllItems,
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
                leading: const Icon(Icons.info_outline, color: Colors.grey),
                title: Text(localizations.aboutApp),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(
                          localizations.aboutApp,
                          style: TextStyle(
                            fontSize: 24,
                          ),
                          textAlign: .center,
                        ),
                        content: Text(
                          localizations.aboutContentText,
                          style: TextStyle(
                            fontSize: 20,
                          ),
                          textAlign: .center,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(localizations.close),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        body: _getCurrentPage(),
        floatingActionButton: _currentPageIndex == 0
          ? AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              transform: Matrix4.translationValues(
                0,
                isFabVisible ? 0 : 120,
                0,
              ),
              child: FloatingActionButton(
                onPressed: _showAddItemDialog,
                child: const Icon(Icons.add),
              ),
            )
          : null,
      )
    );
  }
}
