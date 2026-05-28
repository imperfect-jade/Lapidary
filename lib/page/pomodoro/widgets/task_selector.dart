import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/page/task/task_controller.dart';

import '../pomodoro_controller.dart';
import '../sheets/task_picker_sheet.dart';

/// 空闲态任务选择组件。
///
/// 未选择任务时显示选择按钮；选择任务后显示任务名、开始专注按钮和清除入口。
class PomodoroTaskSelector extends StatelessWidget {
  final PomodoroController controller;
  final TaskController taskController;

  const PomodoroTaskSelector({
    super.key,
    required this.controller,
    required this.taskController,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final taskTitle = controller.currentTaskTitle.value;
      if (taskTitle != null) {
        return Container(
          // 已选择任务区：展示当前任务，并允许直接开始或取消关联。
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.task_alt, size: 18, color: Colors.green),
              const SizedBox(width: 8),
              Flexible(child: Text('当前任务：$taskTitle')),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => controller.startFocus(
                  taskId: controller.currentTaskId.value,
                  taskTitle: taskTitle,
                ),
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('开始专注'),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () {
                  controller.currentTaskId.value = null;
                  controller.currentTaskTitle.value = null;
                },
                child: const Icon(Icons.close, size: 18, color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return OutlinedButton.icon(
        // 未选择任务区：打开任务选择 Sheet，也可以在 Sheet 内选择自由专注。
        onPressed: () => showPomodoroTaskPicker(controller, taskController),
        icon: const Icon(Icons.add_task),
        label: const Text('选择要专注的任务（可选）'),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.78),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    });
  }
}
