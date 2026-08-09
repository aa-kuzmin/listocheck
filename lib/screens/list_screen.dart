import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/settings_service.dart';
import '../services/list_service.dart';
import '../models/checklist_item.dart';
import '../main.dart';

class ListScreen extends StatefulWidget {

  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {

  double _lastScrollOffset = 0;
  bool _isFabVisible = false;

  // Выбор строки
  void _selectItem(int index) {
    setState(() {
      settings.selectedIndex = index;
    });
    settings.save();
  }

  // Переключение состояния чекбокса
  void _toggleItem(int index) {
    setState(() {
      list.items[index].isChecked = !list.items[index].isChecked;
    });
    list.save();
  }

  // Удаление строки
  void _deleteItem(int index) {
    setState(() {
      list.items.removeAt(index);
      if (settings.selectedIndex == index) {
        settings.selectedIndex = null;
      } else if (settings.selectedIndex != null && settings.selectedIndex! > index) {
        settings.selectedIndex = settings.selectedIndex! - 1;
      }
    });
    list.save();
    settings.save();
  }

  // Обработка перетаскивания
  void _onReorderItem(int oldIndex, int newIndex) {
    setState(() {
      final ChecklistItem item = list.items.removeAt(oldIndex);
      list.items.insert(newIndex, item);
      
      if (settings.selectedIndex != null) {
        if (settings.selectedIndex == oldIndex) {
          settings.selectedIndex = newIndex;
        } else {
          final int selected = settings.selectedIndex!;
          if (oldIndex < selected && newIndex >= selected) {
            settings.selectedIndex = selected - 1;
          } else if (oldIndex > selected && newIndex <= selected) {
            settings.selectedIndex = selected + 1;
          }
        }
      }
    });
    list.save();
    settings.save();
  }

  @override
  // Основной вид со списком
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : list.items.isEmpty
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
                  itemCount: list.items.length,
                  proxyDecorator: (child, index, animation) {
                    return child;
                  },
                  itemBuilder: (context, index) {
                    final item = list.items[index];
                    final isSelected = settings.selectedIndex == index;
                    
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
                            fontSize: settings.fontSize,
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

}
