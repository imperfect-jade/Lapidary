import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/page/pet/pet.dart';
import 'package:todolist/page/pomodoro/pomodoro_controller.dart';
import 'package:todolist/page/task/task_controller.dart';

part 'dialogs/settings_dialog.dart';
part 'sheets/task_picker_sheet.dart';
part 'states/idle_state.dart';
part 'states/running_state.dart';
part 'widgets/hints.dart';
part 'widgets/mode_label.dart';
part 'widgets/motivation_quote_ticker.dart';
part 'widgets/task_selector.dart';
part 'widgets/timer_controls.dart';
part 'widgets/timer_panel.dart';
part 'widgets/today_stats.dart';

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
            ? _RunningState(controller: controller)
            : _IdleState(
                controller: controller,
                taskController: taskController,
              );
      }),
    );
  }
}
