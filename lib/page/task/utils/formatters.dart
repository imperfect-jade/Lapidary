import 'package:todolist/model/task/task.dart';

/// 任务列表和详情弹窗共用的日期时间展示格式。
///
/// 输入为任务截止时间或创建时间，输出固定为 `yyyy/MM/dd HH:mm`，确保列表和详情显示一致。
String formatTaskDateTime(DateTime date) {
  return '${date.year}/${_two(date.month)}/${_two(date.day)} ${_two(date.hour)}:${_two(date.minute)}';
}

String _two(int value) => value.toString().padLeft(2, '0');

/// 格式化长期任务的专注目标，用于任务卡片和详情弹窗保持同一展示口径。
///
/// 输入为任务模型，输出包含周期标签和目标分钟数；调用前通常先判断 [TaskModel.hasFocusTarget]。
String formatTaskFocusTarget(TaskModel task) {
  return '目标：${FocusTargetPeriod.labelOf(task.focusTargetPeriod)} ${task.focusTargetMinutes} 分钟';
}
