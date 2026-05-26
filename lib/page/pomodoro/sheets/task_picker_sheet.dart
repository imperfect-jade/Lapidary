import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/page/task/task_controller.dart';

import '../pomodoro_controller.dart';

void showPomodoroTaskPicker(
  PomodoroController controller,
  TaskController taskController,
) {
  Get.bottomSheet(
    Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '选择任务',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...taskController.pendingTasks.map(
            (task) => ListTile(
              title: Text(task.title),
              onTap: () {
                controller.currentTaskId.value = task.id;
                controller.currentTaskTitle.value = task.title;
                controller.startFocus(taskId: task.id, taskTitle: task.title);
                Get.back();
              },
            ),
          ),
          ListTile(
            title: const Text('自由专注（不关联任务）'),
            onTap: () {
              controller.startFocus();
              Get.back();
            },
          ),
        ],
      ),
    ),
  );
}
