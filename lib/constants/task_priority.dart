import 'package:flutter/material.dart';

/// 任务优先级展示配置。
///
/// `value` 与 `TaskModel.priority` 保持一致；四象限页面、任务表单和详情展示
/// 都应复用这里的标签、颜色和图标，避免多个页面对优先级含义解释不一致。
class TaskPriorityOption {
  /// 持久化到任务模型里的优先级值，当前约定为 1-4。
  final int value;

  /// 用户可见的象限名称。
  final String label;

  /// 该象限在 UI 中使用的强调色。
  final Color color;

  /// 该象限在筛选器、卡片或标题中使用的图标。
  final IconData icon;

  /// 四象限页面中显示的简短行动建议。
  final String subtitle;

  const TaskPriorityOption({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
    required this.subtitle,
  });
}

/// 四象限优先级配置，顺序即页面展示顺序。
///
/// 新增或调整优先级含义时，需要同时确认任务表单、四象限、任务详情和奖励规则是否仍一致。
const List<TaskPriorityOption> taskPriorityOptions = [
  TaskPriorityOption(
    value: 1,
    label: '重要且紧急',
    color: Colors.red,
    icon: Icons.priority_high,
    subtitle: '立刻做',
  ),
  TaskPriorityOption(
    value: 2,
    label: '紧急不重要',
    color: Colors.orange,
    icon: Icons.speed,
    subtitle: '快速做',
  ),
  TaskPriorityOption(
    value: 3,
    label: '重要不紧急',
    color: Colors.blue,
    icon: Icons.event_note,
    subtitle: '计划做',
  ),
  TaskPriorityOption(
    value: 4,
    label: '不重要不紧急',
    color: Colors.grey,
    icon: Icons.low_priority,
    subtitle: '尽量少做',
  ),
];

/// 根据任务优先级值查找展示配置。
///
/// 找不到匹配值时回退到“重要不紧急”，避免异常数据导致页面崩溃。
TaskPriorityOption taskPriorityOf(int value) {
  return taskPriorityOptions.firstWhere(
    (option) => option.value == value,
    orElse: () => taskPriorityOptions[2],
  );
}
