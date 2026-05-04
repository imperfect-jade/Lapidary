import 'package:flutter/material.dart';

class TaskPriorityOption {
  final int value;
  final String label;
  final Color color;
  final IconData icon;
  final String subtitle;

  const TaskPriorityOption({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
    required this.subtitle,
  });
}

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

TaskPriorityOption taskPriorityOf(int value) {
  return taskPriorityOptions.firstWhere(
    (option) => option.value == value,
    orElse: () => taskPriorityOptions[2],
  );
}
