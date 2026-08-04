// Класс для хранения одного элемента чеклиста
class ChecklistItem {
  final String name;
  bool isChecked;

  ChecklistItem({
    required this.name,
    required this.isChecked,
  });

  Map<String, dynamic> toYaml() {
    return {
      'name': name,
      'is_checked': isChecked,
    };
  }

  factory ChecklistItem.fromYaml(Map<dynamic, dynamic> json) {
    return ChecklistItem(
      name: json['name'] as String,
      isChecked: json['is_checked'] as bool,
    );
  }
}
