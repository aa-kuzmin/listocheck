import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/l10n.dart';
import 'l10n/generated/app_localizations.dart';

void main() {
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
      //final String systemLanguage = View.of(context).platformDispatcher.locale.languageCode;
      //final String systemLanguage = WidgetsBinding.instance?.platformDispatcher.locale.languageCode ?? 'en';

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

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

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
  List<ChecklistItem> _items = [];
  bool _isLoading = true;
  double _fontSize = 18.0;
  double _titleFontSize = 20.0;
  int? _selectedIndex = 0;
  static const String _fontSizeKey = 'font_size';
  static const String _titleFontSizeKey = 'title_font_size';
  static const String _selectedIndexKey = 'selected_index';
  
  int _currentPageIndex = 0;
  bool _isFabVisible = true;
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    // Загружаем данные после того, как дерево виджетов построено
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadItems();
      _loadFontSize();
      _loadTitleFontSize();
      _loadSelectedIndex();
    });  
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

  // Загрузка размера шрифта элементов из SharedPreferences
  Future<void> _loadFontSize() async {
    final AppLocalizations? localizations = AppLocalizations.of(context);
    try {
      final prefs = await SharedPreferences.getInstance();
      final double? savedFontSize = prefs.getDouble(_fontSizeKey);
      if (savedFontSize != null) {
        setState(() {
          _fontSize = savedFontSize;
        });
      }
    } catch (e) {
      _showErrorMessage(localizations?.errLoadFontSize ?? 'Error loading the font size');
    }
  }

  // Сохранение размера шрифта элементов в SharedPreferences
  Future<void> _saveFontSize() async {
    final AppLocalizations? localizations = AppLocalizations.of(context);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_fontSizeKey, _fontSize);
    } catch (e) {
      _showErrorMessage(localizations?.errSaveFontSize ?? 'Error saving font size');
    }
  }

  // Загрузка размера шрифта заголовка из SharedPreferences
  Future<void> _loadTitleFontSize() async {
    final AppLocalizations? localizations = AppLocalizations.of(context);
    try {
      final prefs = await SharedPreferences.getInstance();
      final double? savedTitleFontSize = prefs.getDouble(_titleFontSizeKey);
      if (savedTitleFontSize != null) {
        setState(() {
          _titleFontSize = savedTitleFontSize;
        });
      }
    } catch (e) {
      _showErrorMessage(localizations?.errLoadTitleFontSize ?? 'Error loading the font size of the title');
    }
  }

  // Сохранение размера шрифта заголовка в SharedPreferences
  Future<void> _saveTitleFontSize() async {
    final AppLocalizations? localizations = AppLocalizations.of(context);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_titleFontSizeKey, _titleFontSize);
    } catch (e) {
      _showErrorMessage(localizations?.errSaveTitleFontSize ?? 'Error saving the font size of the title');
    }
  }

  // Загрузка выбранного индекса из SharedPreferences
  Future<void> _loadSelectedIndex() async {
    final AppLocalizations? localizations = AppLocalizations.of(context);
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? savedIndex = prefs.getInt(_selectedIndexKey);
      if (savedIndex != null && savedIndex >= 0 && savedIndex < _items.length) {
        setState(() {
          _selectedIndex = savedIndex;
        });
      }
    } catch (e) {
      _showErrorMessage(localizations?.errLoadSelInd ?? 'Error loading the selected index');
    }
  }

  // Сохранение выбранного индекса в SharedPreferences
  Future<void> _saveSelectedIndex() async {
    final AppLocalizations? localizations = AppLocalizations.of(context);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_selectedIndex != null) {
        await prefs.setInt(_selectedIndexKey, _selectedIndex!);
      } else {
        await prefs.remove(_selectedIndexKey);
      }
    } catch (e) {
      _showErrorMessage(localizations?.errSaveSelInd ?? 'Error saving the selected index');
    }
  }

  // Увеличение шрифта элементов
  void _increaseFontSize() {
    setState(() {
      _fontSize = (_fontSize + 2.0).clamp(10.0, 40.0);
    });
    _saveFontSize();
  }

  // Уменьшение шрифта элементов
  void _decreaseFontSize() {
    setState(() {
      _fontSize = (_fontSize - 2.0).clamp(10.0, 40.0);
    });
    _saveFontSize();
  }

  // Увеличение шрифта заголовка
  void _increaseTitleFontSize() {
    setState(() {
      _titleFontSize = (_titleFontSize + 2.0).clamp(20.0, 40.0);
    });
    _saveTitleFontSize();
  }

  // Уменьшение шрифта заголовка
  void _decreaseTitleFontSize() {
    setState(() {
      _titleFontSize = (_titleFontSize - 2.0).clamp(20.0, 40.0);
    });
    _saveTitleFontSize();
  }

  // Загрузка списка из SharedPreferences
  Future<void> _loadItems() async {
    final localizations = AppLocalizations.of(context)!;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? itemsJson = prefs.getString('checklist_items');
      
      if (itemsJson != null) {
        final List<dynamic> decodedList = jsonDecode(itemsJson);
        setState(() {
          _items = decodedList.map((item) => ChecklistItem.fromJson(item)).toList();
          _isLoading = false;
        });
        await _loadSelectedIndex();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showErrorMessage(localizations.errLoadList);
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Сохранение списка в SharedPreferences
  Future<void> _saveItems() async {
    final localizations = AppLocalizations.of(context)!;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String itemsJson = jsonEncode(_items.map((item) => item.toJson()).toList());
      await prefs.setString('checklist_items', itemsJson);
    } catch (e) {
      _showErrorMessage(localizations.errSaveList);
    }
  }

  // Выбор элемента
  void _selectItem(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _saveSelectedIndex();
  }

  // Добавление новой строки
  void _addItem(String name) {
    setState(() {
      if (_selectedIndex != null && _selectedIndex! < _items.length) {
        _items.insert(_selectedIndex! + 1, ChecklistItem(name: name, isChecked: false));
        _selectedIndex = _selectedIndex! + 1;
      } else {
        _items.add(ChecklistItem(name: name, isChecked: false));
        _selectedIndex = _items.length - 1;
      }
    });
    _saveItems();
    _saveSelectedIndex();
  }

  // Переключение состояния чекбокса
  void _toggleItem(int index) {
    setState(() {
      _items[index].isChecked = !_items[index].isChecked;
    });
    _saveItems();
  }

  // Удаление товара
  void _deleteItem(int index) {
    setState(() {
      _items.removeAt(index);
      if (_selectedIndex == index) {
        _selectedIndex = null;
      } else if (_selectedIndex != null && _selectedIndex! > index) {
        _selectedIndex = _selectedIndex! - 1;
      }
    });
    _saveItems();
    _saveSelectedIndex();
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
                  for (var item in _items) {
                    item.isChecked = false;
                  }
                });
                _saveItems();
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
                  _items.clear();
                  _selectedIndex = null;
                });
                _saveItems();
                _saveSelectedIndex();
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
      final ChecklistItem item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
      
      if (_selectedIndex != null) {
        if (_selectedIndex == oldIndex) {
          _selectedIndex = newIndex;
        } else {
          final int selected = _selectedIndex!;
          if (oldIndex < selected && newIndex >= selected) {
            _selectedIndex = selected - 1;
          } else if (oldIndex > selected && newIndex <= selected) {
            _selectedIndex = selected + 1;
          }
        }
      }
    });
    _saveItems();
    _saveSelectedIndex();
  }

  // Основной вид со списком
  Widget _buildListPage() {
    final localizations = AppLocalizations.of(context)!;
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _items.isEmpty
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
                  itemCount: _items.length,
                  proxyDecorator: (child, index, animation) {
                    return child;
                  },
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final isSelected = _selectedIndex == index;
                    
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
                            fontSize: _fontSize,
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
                      onPressed: _fontSize > 10 ? _decreaseFontSize : null,
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
                        '${_fontSize.toInt()}',
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
                      onPressed: _fontSize < 40 ? _increaseFontSize : null,
                      tooltip: localizations.increase,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '${localizations.fontSize}: ${_fontSize.toInt()} px',
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
                      fontSize: _fontSize,
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
                      onPressed: _titleFontSize > 20 ? _decreaseTitleFontSize : null,
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
                        '${_titleFontSize.toInt()}',
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
                      onPressed: _titleFontSize < 40 ? _increaseTitleFontSize : null,
                      tooltip: localizations.increase,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '${localizations.fontSize}: ${_titleFontSize.toInt()} px',
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
                      fontSize: _titleFontSize,
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
        return _buildListPage();
      case 1:
        return _buildSettingsPage();
      case 2:
        return _buildProfilePage();
      default:
        return _buildListPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
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
            fontSize: _titleFontSize,
          ),
        ),
        actions: [
          // Показываем кнопки только на странице списка
          if (_currentPageIndex == 0) ...[
            IconButton(
              icon: const Icon(Icons.check_box_outline_blank),
              onPressed: _items.isEmpty ? null : _uncheckAllItems,
              tooltip: localizations.uncheckAllTooltip,
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              onPressed: _items.isEmpty ? null : _clearAllItems,
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
    );
  }
}

// Класс для хранения одного элемента чеклиста
class ChecklistItem {
  final String name;
  bool isChecked;

  ChecklistItem({
    required this.name,
    required this.isChecked,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'isChecked': isChecked,
    };
  }

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      name: json['name'] as String,
      isChecked: json['isChecked'] as bool,
    );
  }
}
