import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/page/task/task_controller.dart';

import '../pomodoro_controller.dart';

/// 显示番茄钟任务选择底部 Sheet。
///
/// 用户可以选择一个未完成待办开始专注，也可以选择自由专注不关联任务。
void showPomodoroTaskPicker(
  PomodoroController controller,
  TaskController taskController,
) {
  Get.bottomSheet(
    // 任务选择 Sheet UI：展示待完成任务列表，底部提供自由专注入口。
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
              // 关联任务入口：记录任务 id/title，并立即启动一轮专注。
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
            // 自由专注入口：不设置任务 id/title，仍会创建番茄钟记录。
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
