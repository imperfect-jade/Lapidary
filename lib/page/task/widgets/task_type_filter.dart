part of '../task.dart';

class _TaskTypeFilter extends StatelessWidget {
  final String? selectedType;
  final ValueChanged<String?> onSelected;

  const _TaskTypeFilter({required this.selectedType, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final filters = <String?, String>{
      null: '全部',
      TaskType.day: '日任务',
      TaskType.week: '周任务',
      TaskType.month: '月任务',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 2),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: filters.entries.map((entry) {
          final selected = selectedType == entry.key;
          return ChoiceChip(
            label: Text(entry.value),
            selected: selected,
            onSelected: (_) => onSelected(entry.key),
            selectedColor: TaskTheme.appBarColor,
            backgroundColor: Colors.white.withValues(alpha: 0.76),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            labelStyle: TextStyle(
              fontSize: 12,
              color: selected ? Colors.black : Colors.grey[700],
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          );
        }).toList(),
      ),
    );
  }
}
