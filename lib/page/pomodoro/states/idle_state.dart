import 'package:flutter/material.dart';
import 'package:todolist/page/task/task_controller.dart';

import '../pomodoro_controller.dart';
import '../widgets/hints.dart';
import '../widgets/task_selector.dart';
import '../widgets/timer_panel.dart';
import '../widgets/today_stats.dart';

/// 番茄钟空闲态页面内容。
///
/// 展示今日统计、开始计时圆盘、任务选择入口和使用提示；不会主动启动计时。
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
        // 空闲态整体可滚动，避免小屏幕上统计、圆盘和任务选择被挤出屏幕。
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: Column(
              children: [
                // 今日统计区：由 PomodoroController 的今日分钟数和番茄数驱动。
                PomodoroTodayStats(controller: controller),
                SizedBox(height: constraints.maxHeight < 620 ? 28 : 56),
                // 开始圆盘区：显示默认专注时长，点击圆盘可打开设置弹窗。
                PomodoroStartCircle(controller: controller),
                const SizedBox(height: 24),
                // 任务选择区：可关联待办任务开始专注，也可保持自由专注。
                PomodoroTaskSelector(
                  controller: controller,
                  taskController: taskController,
                ),
                const SizedBox(height: 18),
                // 提示区：说明任务选择和计时器设置入口。
                const PomodoroHint(),
              ],
            ),
          ),
        );
      },
    );
  }
}
