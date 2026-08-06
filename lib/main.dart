import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'l10n/l10n.dart';
import 'l10n/generated/app_localizations.dart';

import 'models/checklist_item.dart';
import 'services/settings_service.dart';
import 'services/list_service.dart';
import 'utils/errors.dart';

void main() {

  WidgetsFlutterBinding.ensureInitialized();
  
  // Принудительно показываем системную навигацию
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [
      SystemUiOverlay.top,    // Статус-бар
      SystemUiOverlay.bottom, // Системная навигация
    ],
  );

  // Настройка цветов системной панели
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      // делаем фон непрозрачным белым
      systemNavigationBarColor: Colors.white,
      systemNavigationBarDividerColor: Colors.grey,
      systemNavigationBarIconBrightness: Brightness.dark,
      
      // Статус-бар тоже настраиваем
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

}

class _MyAppState extends State<MyApp> {
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
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        debugShowCheckedModeBanner: false,
      );
    }

    return MaterialApp(
      title: _locale.languageCode == 'ru' ? 'Листочек' : 'Listocheck',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(),
      debugShowCheckedModeBanner: false,
      locale: _locale,
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final SettingsService _settings = SettingsService();
  final ListService _list = ListService();

  bool _isLoading = true;

  int _currentPageIndex = 0;
  bool _isFabVisible = true;
  double _lastScrollOffset = 0;

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

    var result = await _settings.load();
    if (result is Failure) {
      _showErrorMessage(localizations.errLoadSettings);
    } else {
      if (result is Success && result.data != null) {
        setState((){});
      }
    }

    result = await _list.load();
    if (result is Failure) {
      _showErrorMessage(localizations.errLoadList);
    } else {
      if (result is Success && result.data != null) {
        setState((){});
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
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

  // Увеличение шрифта элементов
  void _increaseFontSize() {
    setState(() {
      _settings.fontSize = (_settings.fontSize + 2.0).clamp(10.0, 40.0);
    });
    _settings.save();
  }

  // Уменьшение шрифта элементов
  void _decreaseFontSize() {
    setState(() {
      _settings.fontSize = (_settings.fontSize - 2.0).clamp(10.0, 40.0);
    });
    _settings.save();
  }

  // Увеличение шрифта заголовка
  void _increaseTitleFontSize() {
    setState(() {
      _settings.titleFontSize = (_settings.titleFontSize + 2.0).clamp(20.0, 40.0);
    });
    _settings.save();
  }

  // Уменьшение шрифта заголовка
  void _decreaseTitleFontSize() {
    setState(() {
      _settings.titleFontSize = (_settings.titleFontSize - 2.0).clamp(20.0, 40.0);
    });
    _settings.save();
  }

  // Выбор элемента
  void _selectItem(int index) {
    setState(() {
      _settings.selectedIndex = index;
    });
    _settings.save();
  }

  // Добавление новой строки
  void _addItem(String name) {
    setState(() {
      if (_settings.selectedIndex != null && _settings.selectedIndex! < _list.items.length) {
        _list.items.insert(_settings.selectedIndex! + 1, ChecklistItem(name: name, isChecked: false));
        _settings.selectedIndex = _settings.selectedIndex! + 1;
      } else {
        _list.items.add(ChecklistItem(name: name, isChecked: false));
        _settings.selectedIndex = _list.items.length - 1;
      }
    });
    _list.save();
    _settings.save();
  }

  // Переключение состояния чекбокса
  void _toggleItem(int index) {
    setState(() {
      _list.items[index].isChecked = !_list.items[index].isChecked;
    });
    _list.save();
  }

  // Удаление товара
  void _deleteItem(int index) {
    setState(() {
      _list.items.removeAt(index);
      if (_settings.selectedIndex == index) {
        _settings.selectedIndex = null;
      } else if (_settings.selectedIndex != null && _settings.selectedIndex! > index) {
        _settings.selectedIndex = _settings.selectedIndex! - 1;
      }
    });
    _list.save();
    _settings.save();
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
                  for (var item in _list.items) {
                    item.isChecked = false;
                  }
                });
                _list.save();
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
                  _list.items.clear();
                  _settings.selectedIndex = null;
                });
                _list.save();
                _settings.save();
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

  // Обработка перетаскивания
  void _onReorderItem(int oldIndex, int newIndex) {
    setState(() {
      final ChecklistItem item = _list.items.removeAt(oldIndex);
      _list.items.insert(newIndex, item);
      
      if (_settings.selectedIndex != null) {
        if (_settings.selectedIndex == oldIndex) {
          _settings.selectedIndex = newIndex;
        } else {
          final int selected = _settings.selectedIndex!;
          if (oldIndex < selected && newIndex >= selected) {
            _settings.selectedIndex = selected - 1;
          } else if (oldIndex > selected && newIndex <= selected) {
            _settings.selectedIndex = selected + 1;
          }
        }
      }
    });
    _list.save();
    _settings.save();
  }

  // Основной вид со списком
  Widget _buildListPage() {
    final localizations = AppLocalizations.of(context)!;
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _list.items.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.list_alt,
                      size: 80,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      '${localizations.listEmpty}\n${localizations.listEmptyHint}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification notification) {
                  if (notification is ScrollUpdateNotification) {
                    final currentOffset = notification.metrics.pixels;
                    
                    if (currentOffset > 10) {
                      if (currentOffset < _lastScrollOffset) {
                        if (!_isFabVisible) {
                          setState(() => _isFabVisible = true);
                        }
                      } else if (currentOffset > _lastScrollOffset) {
                        if (_isFabVisible) {
                          setState(() => _isFabVisible = false);
                        }
                      }
                    } else {
                      if (!_isFabVisible) {
                        setState(() => _isFabVisible = true);
                      }
                    }
                    
                    _lastScrollOffset = currentOffset;
                  }
                  return true;
                },
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  onReorderItem: _onReorderItem,
                  itemCount: _list.items.length,
                  proxyDecorator: (child, index, animation) {
                    return child;
                  },
                  itemBuilder: (context, index) {
                    final item = _list.items[index];
                    final isSelected = _settings.selectedIndex == index;
                    
                    return Card(
                      key: ValueKey(item.name + index.toString()),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      color: Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide.none,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 0,
                        ),
                        leading: Checkbox(
                          value: item.isChecked,
                          onChanged: (_) => _toggleItem(index),
                        ),
                        title: Text(
                          item.name,
                          style: TextStyle(
                            fontSize: _settings.fontSize,
                            decoration: item.isChecked
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: isSelected 
                                ? Colors.deepPurple
                                : (item.isChecked ? Colors.grey : Colors.black),
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.reorder,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _deleteItem(index),
                            ),
                          ],
                        ),
                        onTap: () => _selectItem(index),
                      ),
                    );
                  },
                ),
              );
  }

  // Вид настроек
  Widget _buildSettingsPage() {
    final localizations = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const SizedBox(height: 24),
          Text(
            localizations.fontSettings,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          
          // Настройка шрифта элементов списка
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.itemFont,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 40),
                      onPressed: _settings.fontSize > 10 ? _decreaseFontSize : null,
                      tooltip: localizations.decrease,
                    ),
                    const SizedBox(width: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_settings.fontSize.toInt()}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 40),
                      onPressed: _settings.fontSize < 40 ? _increaseFontSize : null,
                      tooltip: localizations.increase,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '${localizations.fontSize}: ${_settings.fontSize.toInt()} px',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    localizations.exampleText,
                    style: TextStyle(
                      fontSize: _settings.fontSize,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Настройка шрифта заголовка
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.titleFont,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 40),
                      onPressed: _settings.titleFontSize > 20 ? _decreaseTitleFontSize : null,
                      tooltip: localizations.decrease,
                    ),
                    const SizedBox(width: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_settings.titleFontSize.toInt()}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 40),
                      onPressed: _settings.titleFontSize < 40 ? _increaseTitleFontSize : null,
                      tooltip: localizations.increase,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '${localizations.fontSize}: ${_settings.titleFontSize.toInt()} px',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    localizations.exampleTitle,
                    style: TextStyle(
                      fontSize: _settings.titleFontSize,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Вид профиля
  Widget _buildProfilePage() {
    final localizations = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 24),
          Text(
            localizations.profile,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Text(
            localizations.inDevelopment,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // Получение текущей страницы
  Widget _getCurrentPage() {
    switch (_currentPageIndex) {
      case 0:
        return SafeArea(child: _buildListPage());
      case 1:
        return SafeArea(child: _buildSettingsPage());
      case 2:
        return SafeArea(child: _buildProfilePage());
      default:
        return SafeArea(child: _buildListPage());
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
              fontSize: _settings.titleFontSize,
            ),
          ),
          actions: [
            // Показываем кнопки только на странице списка
            if (_currentPageIndex == 0) ...[
              IconButton(
                icon: const Icon(Icons.check_box_outline_blank),
                onPressed: _list.items.isEmpty ? null : _uncheckAllItems,
                tooltip: localizations.uncheckAllTooltip,
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep, color: Colors.red),
                onPressed: _list.items.isEmpty ? null : _clearAllItems,
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
                _isFabVisible ? 0 : 120,
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

