import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/generated/app_localizations.dart';
import '../main.dart';

// Создаем GlobalKey для доступа к состоянию ListScreen
final listScreenKey = GlobalKey<_ListScreenState>();

class ListScreen extends ConsumerStatefulWidget {
  const ListScreen({super.key});

  @override
  ConsumerState<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends ConsumerState<ListScreen> {
  // Храним индекс редактируемой строки
  int? _editingIndex;
  // Контроллер для текстового поля
  final TextEditingController _textController = TextEditingController();
  
  // Флаг для предотвращения множественных вызовов
  bool _isAdding = false;

  // Публичный метод для добавления новой пустой строки
  void addNewEmptyItem() {
    // Предотвращаем множественные вызовы
    if (_isAdding) return;
    _isAdding = true;
    
    try {
      // Если какая-то строка в режиме редактирования - сначала сохраняем
      if (_editingIndex != null) {
        // Сохраняем изменения текущей строки
        _saveEditing();
      }
      
      // Добавляем новую строку
      _addNewItemAfterSave();
    } catch (e) {
      if (kDebugMode) print('Ошибка при добавлении строки: $e');
    } finally {
      // Сбрасываем флаг после завершения
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isAdding = false;
      });
    }
  }
  
  // Вспомогательный метод для добавления новой строки
  void _addNewItemAfterSave() {
    try {
      final listNotifier = ref.read(listProvider.notifier);
      final settingsNotifier = ref.read(settingsProvider.notifier);
      final currentList = ref.read(listProvider);
      
      if (kDebugMode) {
        print('Текущий список: ${currentList.items.length} элементов');
        print('Выделенный индекс: ${ref.read(settingsProvider).selectedIndex}');
      }
      
      int insertIndex;
      
      // Если список пуст, сбрасываем выделенный индекс и вставляем в начало
      if (currentList.items.isEmpty) {
        insertIndex = 0;
        // Сбрасываем выделенный индекс, так как он невалидный
        settingsNotifier.setSelectedIndex(null);
      } else {
        final settings = ref.read(settingsProvider);
        // Проверяем валидность выделенного индекса
        if (settings.selectedIndex >= 0 &&
            settings.selectedIndex < currentList.items.length) {
          insertIndex = settings.selectedIndex + 1;
        } else {
          // Если выделенный индекс невалидный, вставляем в конец
          insertIndex = currentList.items.length;
          // Сбрасываем невалидный индекс
          settingsNotifier.setSelectedIndex(null);
        }
      }
      
      if (kDebugMode) print('Индекс вставки: $insertIndex');
      
      // Добавляем пустую строку по указанному индексу
      listNotifier.addItem(insertIndex, '');
      
      // Проверяем, что строка действительно добавилась
      final updatedList = ref.read(listProvider);
      if (insertIndex < updatedList.items.length) {
        if (kDebugMode) print('Строка успешно добавлена. Новый размер: ${updatedList.items.length}');
        
        // Обновляем выделенный индекс на новую строку
        settingsNotifier.setSelectedIndex(insertIndex);
        
        // Сразу переходим в режим редактирования новой строки
        _startEditing(insertIndex);
      } else {
        if (kDebugMode) print('ОШИБКА: Строка не была добавлена!');
      }
    } catch (e) {
      if (kDebugMode) print('Ошибка в _addNewItemAfterSave: $e');
      // Восстанавливаем состояние
      setState(() {
        _editingIndex = null;
        _textController.clear();
      });
    }
  }

  // Выбор строки
  void _selectItem(int index) {
    // Если какая-то строка в режиме редактирования - сохраняем изменения
    if (_editingIndex != null) {
      _saveEditing();
    }
    
    final settingsNotifier = ref.read(settingsProvider.notifier);
    settingsNotifier.setSelectedIndex(index);
  }

  // Переключение состояния чекбокса
  void _toggleItem(int index) {
    // Если какая-то строка в режиме редактирования - сохраняем изменения
    if (_editingIndex != null) {
      _saveEditing();
    }
    
    final listNotifier = ref.read(listProvider.notifier);
    setState(() {
      listNotifier.toggleItem(index);
    });
  }

  // Удаление строки
  void _deleteItem(int index) {
    // Если строка в режиме редактирования - отменяем редактирование
    if (_editingIndex == index) {
      _cancelEditing();
    } else if (_editingIndex != null) {
      // Если редактируется другая строка - сохраняем изменения
      _saveEditing();
    }
    
    final listNotifier = ref.read(listProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    listNotifier.deleteItem(index);
    if (settings.selectedIndex == index) {
      settingsNotifier.setSelectedIndex(null);
    } else if (settings.selectedIndex > index) {
      settingsNotifier.setSelectedIndex(settings.selectedIndex - 1);
    }
  }

  // Обработка перетаскивания
  void _onReorderItem(int oldIndex, int newIndex) {
    // Если какая-то строка в режиме редактирования - сохраняем изменения
    if (_editingIndex != null) {
      _saveEditing();
    }
    
    final listNotifier = ref.read(listProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    listNotifier.reorder(oldIndex, newIndex);
    
    if (settings.selectedIndex == oldIndex) {
      settingsNotifier.setSelectedIndex(newIndex);
    } else {
      final int selected = settings.selectedIndex!;
      if (oldIndex < selected && newIndex >= selected) {
        settingsNotifier.setSelectedIndex(selected - 1);
      } else if (oldIndex > selected && newIndex <= selected) {
        settingsNotifier.setSelectedIndex(selected + 1);
      }
    }
  }

  // Начало редактирования
  void _startEditing(int index) {
    try {
      final currentList = ref.read(listProvider);
      if (index < 0 || index >= currentList.items.length) {
        if (kDebugMode) print('ОШИБКА: Индекс $index вне диапазона (0-${currentList.items.length})');
        return;
      }
      
      // Если уже редактируется другая строка - сначала сохраняем её изменения
      if (_editingIndex != null && _editingIndex != index) {
        _saveEditing();
      }
      
      final item = currentList.items[index];
      setState(() {
        _editingIndex = index;
        _textController.text = item.name;
      });
    } catch (e) {
      if (kDebugMode) print('Ошибка в _startEditing: $e');
      setState(() {
        _editingIndex = null;
        _textController.clear();
      });
    }
  }

  // Завершение редактирования (сохранение)
  void _saveEditing() {
    if (_editingIndex != null) {
      try {
        final newName = _textController.text.trim();
        // Сохраняем изменения даже если строка пустая
        final listNotifier = ref.read(listProvider.notifier);
        listNotifier.updateItemName(_editingIndex!, newName);
        setState(() {
          _editingIndex = null;
          _textController.clear();
        });
      } catch (e) {
        if (kDebugMode) print('Ошибка в _saveEditing: $e');
        setState(() {
          _editingIndex = null;
          _textController.clear();
        });
      }
    }
  }

  // Отмена редактирования
  void _cancelEditing() {
    if (_editingIndex != null) {
      // Просто выходим из режима редактирования без сохранения
      // Строка остается в том виде, в котором была
      setState(() {
        _editingIndex = null;
        _textController.clear();
      });
    }
  }
  
  // Сброс состояния редактирования (вызывается при очистке списка)
  void resetEditingState() {
    setState(() {
      _editingIndex = null;
      _textController.clear();
      _isAdding = false;
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final list = ref.watch(listProvider);
    final settings = ref.watch(settingsProvider);
    final enterItemHint = localizations.enterItem;

    // Слушаем изменения списка и сбрасываем состояние редактирования если список пуст
    if (list.items.isEmpty && _editingIndex != null) {
      // Используем WidgetsBinding для безопасного сброса состояния
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && list.items.isEmpty && _editingIndex != null) {
          setState(() {
            _editingIndex = null;
            _textController.clear();
          });
        }
      });
    }

    return list.items.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.list_alt,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  '${localizations.listEmpty}\n${localizations.listEmptyHint}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        : ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            onReorderItem: _onReorderItem,
            itemCount: list.items.length,
            proxyDecorator: (child, index, animation) {
              return child;
            },
            itemBuilder: (context, index) {
              final item = list.items[index];
              final isSelected = settings.selectedIndex == index;
              final isEditing = _editingIndex == index;

              return Container(
                key: ValueKey(item.name + index.toString()),
                margin: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 2,
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 0,
                    ),
                    leading: Checkbox(
                      value: item.isChecked,
                      onChanged: isEditing ? null : (_) => _toggleItem(index),
                    ),
                    title: isEditing
                        ? TextField(
                            controller: _textController,
                            autofocus: true,
                            style: TextStyle(
                              fontSize: settings.fontSize,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 0),
                              hintText: enterItemHint,
                              hintStyle: TextStyle(
                                fontSize: settings.fontSize,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            onSubmitted: (_) => _saveEditing(),
                          )
                        : Text(
                            item.name.isEmpty ? localizations.empty : item.name,
                            style: TextStyle(
                              fontSize: settings.fontSize,
                              decoration: item.isChecked
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              color: isSelected
                                  ? Colors.deepPurple
                                  : (item.isChecked 
                                      ? Colors.grey 
                                      : (item.name.isEmpty ? Colors.grey.shade400 : Colors.black)),
                              fontWeight: item.name.isEmpty ? FontWeight.w300 : FontWeight.normal,
                              fontStyle: item.name.isEmpty ? FontStyle.italic : FontStyle.normal,
                            ),
                          ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isEditing) ...[
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: _saveEditing,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: _cancelEditing,
                          ),
                        ] else ...[
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                            onPressed: () => _startEditing(index),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _deleteItem(index),
                          ),
                        ],
                      ],
                    ),
                    onTap: isEditing ? null : () => _selectItem(index),
                  ),
                ),
              );
            },
          );
  }
}