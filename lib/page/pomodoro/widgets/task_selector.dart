part of '../pomodoro.dart';

class _TaskSelector extends StatelessWidget {
  final PomodoroController controller;
  final TaskController taskController;

  const _TaskSelector({required this.controller, required this.taskController});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final taskTitle = controller.currentTaskTitle.value;
      if (taskTitle != null) {
        return Container(
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
        onPressed: () => _showTaskPicker(controller, taskController),
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
