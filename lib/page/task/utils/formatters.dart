import 'package:todolist/model/task/task.dart';

String formatTaskDateTime(DateTime date) {
  return '${date.year}/${_two(date.month)}/${_two(date.day)} ${_two(date.hour)}:${_two(date.minute)}';
}

String _two(int value) => value.toString().padLeft(2, '0');

String formatTaskFocusTarget(TaskModel task) {
  return '目标：${FocusTargetPeriod.labelOf(task.focusTargetPeriod)} ${task.focusTargetMinutes} 分钟';
}
