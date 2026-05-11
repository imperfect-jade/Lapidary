part of '../task.dart';

String _formatDateTime(DateTime date) {
  return '${date.year}/${_two(date.month)}/${_two(date.day)} ${_two(date.hour)}:${_two(date.minute)}';
}

String _two(int value) => value.toString().padLeft(2, '0');

String _formatFocusTarget(TaskModel task) {
  return '目标：${FocusTargetPeriod.labelOf(task.focusTargetPeriod)} ${task.focusTargetMinutes} 分钟';
}
