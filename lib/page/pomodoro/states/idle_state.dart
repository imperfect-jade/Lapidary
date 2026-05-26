import 'package:flutter/material.dart';
import 'package:todolist/page/task/task_controller.dart';

import '../pomodoro_controller.dart';
import '../widgets/hints.dart';
import '../widgets/task_selector.dart';
import '../widgets/timer_panel.dart';
import '../widgets/today_stats.dart';

class PomodoroIdleState extends StatelessWidget {
  final PomodoroController controller;
  final TaskController taskController;

  const PomodoroIdleState({
    super.key,
    required this.controller,
    required this.taskController,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: Column(
              children: [
                PomodoroTodayStats(controller: controller),
                SizedBox(height: constraints.maxHeight < 620 ? 28 : 56),
                PomodoroStartCircle(controller: controller),
                const SizedBox(height: 24),
                PomodoroTaskSelector(
                  controller: controller,
                  taskController: taskController,
                ),
                const SizedBox(height: 18),
                const PomodoroHint(),
              ],
            ),
          ),
        );
      },
    );
  }
}
