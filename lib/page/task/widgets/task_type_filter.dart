import 'package:flutter/material.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/model/task/task.dart';

/// 任务类型筛选条。
///
/// 筛选状态由 TaskPage 持有，组件本身只负责展示选项和回传选择结果。
class TaskTypeFilter extends StatelessWidget {
  final String? selectedType;
  final ValueChanged<String?> onSelected;

  const TaskTypeFilter({
    super.key,
    required this.selectedType,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    // 筛选项映射：null 表示“全部”，其余 key 对应 TaskType 中的任务类型。
    final filters = <String?, String>{
      null: '全部',
      TaskType.day: '日任务',
      TaskType.week: '周任务',
      TaskType.month: '月任务',
    };

    return Container(
      // 筛选条 UI：使用紧凑 ChoiceChip，放在任务列表上方快速切换显示范围。
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
