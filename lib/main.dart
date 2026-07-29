import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Включаем полноэкранный режим
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return MaterialApp(
      title: 'Листочек',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(),
      debugShowCheckedModeBanner: false,
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
  
  // Убираем _selectedTabIndex, используем страницу
  int _currentPageIndex = 0; // 0 - список, 1 - настройки, 2 - профиль

  bool _isFabVisible = true;
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _loadItems();
    _loadFontSize();
    _loadTitleFontSize();
    _loadSelectedIndex();
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final double? savedFontSize = prefs.getDouble(_fontSizeKey);
      if (savedFontSize != null) {
        setState(() {
          _fontSize = savedFontSize;
        });
      }
    } catch (e) {
      _showErrorMessage('Ошибка загрузки размера шрифта');
    }
  }

  // Сохранение размера шрифта элементов в SharedPreferences
  Future<void> _saveFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_fontSizeKey, _fontSize);
    } catch (e) {
      _showErrorMessage('Ошибка сохранения размера шрифта');
    }
  }

  // Загрузка размера шрифта заголовка из SharedPreferences
  Future<void> _loadTitleFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final double? savedTitleFontSize = prefs.getDouble(_titleFontSizeKey);
      if (savedTitleFontSize != null) {
        setState(() {
          _titleFontSize = savedTitleFontSize;
        });
      }
    } catch (e) {
      _showErrorMessage('Ошибка загрузки размера шрифта заголовка');
    }
  }

  // Сохранение размера шрифта заголовка в SharedPreferences
  Future<void> _saveTitleFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_titleFontSizeKey, _titleFontSize);
    } catch (e) {
      _showErrorMessage('Ошибка сохранения размера шрифта заголовка');
    }
  }

  // Загрузка выбранного индекса из SharedPreferences
  Future<void> _loadSelectedIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? savedIndex = prefs.getInt(_selectedIndexKey);
      if (savedIndex != null && savedIndex >= 0 && savedIndex < _items.length) {
        setState(() {
          _selectedIndex = savedIndex;
        });
      }
    } catch (e) {
      _showErrorMessage('Ошибка загрузки выбранного индекса');
    }
  }

  // Сохранение выбранного индекса в SharedPreferences
  Future<void> _saveSelectedIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_selectedIndex != null) {
        await prefs.setInt(_selectedIndexKey, _selectedIndex!);
      } else {
        await prefs.remove(_selectedIndexKey);
      }
    } catch (e) {
      _showErrorMessage('Ошибка сохранения выбранного индекса');
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
      _showErrorMessage('Ошибка загрузки списка');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Сохранение списка в SharedPreferences
  Future<void> _saveItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String itemsJson = jsonEncode(_items.map((item) => item.toJson()).toList());
      await prefs.setString('checklist_items', itemsJson);
    } catch (e) {
      _showErrorMessage('Ошибка сохранения списка');
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Снять пометку?'),
          content: const Text('Пометка будет снята у всех элементов списка.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
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
                _showInfoMessage('Отметки сняты со всех элементов');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Снять'),
            ),
          ],
        );
      },
    );
  }

  // Очистка всего списка
  void _clearAllItems() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Очистить список?'),
          content: const Text('Все строки будут удалены без возможности восстановления'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
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
                _showInfoMessage('Список очищен');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Очистить'),
            ),
          ],
        );
      },
    );
  }

  // Диалог добавления строки
  void _showAddItemDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Добавить строку'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Введите строку',
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
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  _addItem(name);
                  Navigator.pop(context);
                }
              },
              child: const Text('Добавить'),
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
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _items.isEmpty
            ? const Center(
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
                      'Список пуст\r\nНажмите на кнопку "+" внизу\r\nчтобы добавить строку\r\nДанные сохраняются автоматически',
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const SizedBox(height: 24),
          const Text(
            'Настройки шрифта',
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
                const Text(
                  'Шрифт элементов списка',
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
                      tooltip: 'Уменьшить шрифт',
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
                      tooltip: 'Увеличить шрифт',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Размер: ${_fontSize.toInt()} px',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Пример текста',
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
                const Text(
                  'Шрифт заголовка',
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
                      tooltip: 'Уменьшить шрифт заголовка',
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
                      tooltip: 'Увеличить шрифт заголовка',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Размер: ${_titleFontSize.toInt()} px',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Пример заголовка',
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
    return const Center(
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
            'Профиль',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'В разработке',
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
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              tooltip: 'Открыть меню',
            );
          },
        ),
        title: Text(
          _currentPageIndex == 0 ? 'Список' : '',
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
              tooltip: 'Снять отметку у всех',
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              onPressed: _items.isEmpty ? null : _clearAllItems,
              tooltip: 'Очистить список',
            ),
          ],
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Листочек',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Минималистичный список',
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
              title: const Text('Список'),
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
              title: const Text('Настройки'),
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
              title: const Text('Профиль'),
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
              title: const Text('О приложении'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text(
                        'О приложении',
                        style: TextStyle(
                          fontSize: 24,
                        ),
                        textAlign: .center,
                      ),
                      content: Text(
                        'ЛИСТОЧЕК v1.0\n\n'
                        'Минималистичное приложение для ведения списка\n\n'
                        '©️Алексей А. Кузьмин',
                        style: TextStyle(
                          fontSize: 20,
                        ),
                        textAlign: .center,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Закрыть'),
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
