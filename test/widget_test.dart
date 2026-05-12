import 'package:flutter_test/flutter_test.dart';
import 'package:todolist/model/task/task.dart';

void main() {
  test('task helpers expose stable labels and focus target state', () {
    final task = TaskModel(
      id: 'task-1',
      title: '示例任务',
      deadline: DateTime(2026, 5, 12, 10),
      taskType: TaskType.week,
      focusTargetMinutes: 25,
    );

    expect(TaskType.labelOf(TaskType.day), '日任务');
    expect(FocusTargetPeriod.labelOf(FocusTargetPeriod.daily), '每天');
    expect(task.hasFocusTarget, isTrue);
  });
}
