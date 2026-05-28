import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/page/pomodoro/pomodoro_controller.dart';
import 'package:todolist/page/task/task_controller.dart';

import 'package:todolist/page/pomodoro/states/idle_state.dart';
import 'package:todolist/page/pomodoro/states/running_state.dart';

/// 番茄钟页面入口。
///
/// 页面只负责在空闲态和运行态之间切换，计时逻辑、记录保存和奖励反馈都交给 [PomodoroController]。
class PomodoroPage extends StatelessWidget {
  const PomodoroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PomodoroController>();
    final taskController = Get.find<TaskController>();

    // 页面骨架：顶部标题栏 + 根据计时状态切换的主体内容。
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
        // 主体状态区：运行时展示倒计时和控制按钮，空闲时展示统计、开始圆盘和任务选择。
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
