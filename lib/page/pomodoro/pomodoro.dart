import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/page/pomodoro/pomodoro_controller.dart';
import 'package:todolist/page/task/task_controller.dart';

import 'package:todolist/page/pomodoro/states/idle_state.dart';
import 'package:todolist/page/pomodoro/states/running_state.dart';

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
      ),
      body: Obx(() {
        final isRunning = controller.isRunning.value;
        return isRunning
            ? PomodoroRunningState(controller: controller)
            : PomodoroIdleState(
                controller: controller,
                taskController: taskController,
              );
      }),
    );
  }
}
