import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/generated/app_localizations.dart';
import '../main.dart';

class ListScreen extends ConsumerStatefulWidget {

  const ListScreen({super.key});

  @override
  ConsumerState<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends ConsumerState<ListScreen> {

  // Выбор строки
  void _selectItem(int index) {
    final settingsNotifier = ref.read(settingsProvider.notifier);
      settingsNotifier.setSelectedIndex(index);
  }

  // Переключение состояния чекбокса
  void _toggleItem(int index) {
    final listNotifier = ref.read(listProvider.notifier);
    setState(() {
      listNotifier.toggleItem(index);
    });
  }

  // Удаление строки
  void _deleteItem(int index) {
    final listNotifier = ref.read(listProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    listNotifier.deleteItem(index);
    if (settings.selectedIndex == index) {
      settingsNotifier.setSelectedIndex(null);
    } else if (settings.selectedIndex != null && settings.selectedIndex! > index) {
      settingsNotifier.setSelectedIndex(settings.selectedIndex! - 1);
    }
  }

  // Обработка перетаскивания
  void _onReorderItem(int oldIndex, int newIndex) {
    final listNotifier = ref.read(listProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    listNotifier.reorder(oldIndex, newIndex);
    
    if (settings.selectedIndex != null) {
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
  }

  @override
  // Основной вид со списком
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final list = ref.watch(listProvider);
    final settings = ref.watch(settingsProvider);
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
                      )
                    );
                  },
                );
  }

}
