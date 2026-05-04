import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/page/pomodoro/pomodoro_controller.dart';
import 'package:todolist/page/task/task_controller.dart';

//番茄钟页面
class PomodoroPage extends StatelessWidget {
  const PomodoroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PomodoroController>();
    final taskController = Get.find<TaskController>();

    return Scaffold(
      backgroundColor: TaskTheme.primaryColor,
      appBar: AppBar(
        title: const Text('番茄钟'),
        centerTitle: true,
        backgroundColor: TaskTheme.appBarColor,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(controller),
          ),
        ],
      ),
      body: Obx(() {
        final isRunning = controller.isRunning.value;
        return isRunning
            ? _RunningState(controller: controller)
            : _IdleState(
                controller: controller,
                taskController: taskController,
              );
      }),
    );
  }

  void _showSettings(PomodoroController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('番茄钟设置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('专注时长：'),
                Obx(
                  () => DropdownButton<int>(
                    value: controller.focusDuration.value,
                    items: [15, 25, 30, 45, 60]
                        .map(
                          (v) =>
                              DropdownMenuItem(value: v, child: Text('$v分钟')),
                        )
                        .toList(),
                    onChanged: (v) => controller.focusDuration.value = v ?? 25,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Text('休息时长：'),
                Obx(
                  () => DropdownButton<int>(
                    value: controller.breakDuration.value,
                    items: [5, 10, 15]
                        .map(
                          (v) =>
                              DropdownMenuItem(value: v, child: Text('$v分钟')),
                        )
                        .toList(),
                    onChanged: (v) => controller.breakDuration.value = v ?? 5,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('完成')),
        ],
      ),
    );
  }
}

class _IdleState extends StatelessWidget {
  final PomodoroController controller;
  final TaskController taskController;

  const _IdleState({required this.controller, required this.taskController});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 48),
          _TodayStats(controller: controller),
          const SizedBox(height: 48),
          _TaskSelector(controller: controller, taskController: taskController),
          const SizedBox(height: 48),
          _StartCircle(controller: controller, taskController: taskController),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              '点击上方开始专注',
              style: TextStyle(
                fontSize: 16,
                color: Color.fromARGB(255, 138, 160, 12),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RunningState extends StatelessWidget {
  final PomodoroController controller;

  const _RunningState({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ModeLabel(controller: controller),
          const SizedBox(height: 16),
          _CurrentTaskTitle(controller: controller),
          const SizedBox(height: 32),
          _TimerProgress(controller: controller),
          const SizedBox(height: 48),
          _TimerControls(controller: controller),
        ],
      ),
    );
  }
}

class _TodayStats extends StatelessWidget {
  final PomodoroController controller;

  const _TodayStats({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statCard('今日专注', '${controller.todayFocusMinutes.value}分钟'),
          _statCard('完成番茄', '${controller.todayPomodoroCount.value}个'),
        ],
      );
    });
  }

  Widget _statCard(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _TaskSelector extends StatelessWidget {
  final PomodoroController controller;
  final TaskController taskController;

  const _TaskSelector({required this.controller, required this.taskController});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final taskTitle = controller.currentTaskTitle.value;
      if (taskTitle != null) {
        return Chip(
          label: Text('当前任务：$taskTitle'),
          onDeleted: () {
            controller.currentTaskId.value = null;
            controller.currentTaskTitle.value = null;
          },
        );
      }

      return TextButton.icon(
        onPressed: () => _showTaskPicker(controller, taskController),
        icon: const Icon(Icons.add_task),
        label: const Text('选择要专注的任务（可选）'),
      );
    });
  }
}

class _StartCircle extends StatelessWidget {
  final PomodoroController controller;
  final TaskController taskController;

  const _StartCircle({required this.controller, required this.taskController});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isFocus = controller.currentMode.value == 'focus';
      return GestureDetector(
        onTap: () => _showTaskPicker(controller, taskController),
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFocus
                ? Colors.red.withOpacity(0.1)
                : Colors.green.withOpacity(0.1),
            border: Border.all(
              color: isFocus ? Colors.red : Colors.green,
              width: 4,
            ),
          ),
          child: Center(
            child: Text(
              '${controller.focusDuration.value}:00',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    });
  }
}

class _ModeLabel extends StatelessWidget {
  final PomodoroController controller;

  const _ModeLabel({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isFocus = controller.currentMode.value == 'focus';
      return Text(
        isFocus ? '专注中' : '休息中',
        style: TextStyle(
          fontSize: 20,
          color: isFocus ? Colors.red : Colors.green,
        ),
      );
    });
  }
}

class _CurrentTaskTitle extends StatelessWidget {
  final PomodoroController controller;

  const _CurrentTaskTitle({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final taskTitle = controller.currentTaskTitle.value;
      if (taskTitle == null) {
        return const SizedBox.shrink();
      }
      return Text('当前任务：$taskTitle', style: const TextStyle(fontSize: 16));
    });
  }
}

class _TimerProgress extends StatelessWidget {
  final PomodoroController controller;

  const _TimerProgress({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isFocus = controller.currentMode.value == 'focus';
      return Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 250,
            height: 250,
            child: CircularProgressIndicator(
              value: controller.progress,
              strokeWidth: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(
                isFocus ? Colors.red : Colors.green,
              ),
            ),
          ),
          Text(
            controller.formattedTime,
            style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold),
          ),
        ],
      );
    });
  }
}

class _TimerControls extends StatelessWidget {
  final PomodoroController controller;

  const _TimerControls({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!controller.isPaused.value)
            ElevatedButton.icon(
              onPressed: controller.pause,
              icon: const Icon(Icons.pause),
              label: const Text('暂停'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: controller.resume,
              icon: const Icon(Icons.play_arrow),
              label: const Text('继续'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          const SizedBox(width: 16),
          OutlinedButton(
            onPressed: controller.giveUp,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              foregroundColor: Colors.red,
            ),
            child: const Text('放弃'),
          ),
        ],
      );
    });
  }
}

void _showTaskPicker(
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
