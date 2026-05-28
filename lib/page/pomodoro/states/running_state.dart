import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/page/pet/widgets/pet_focus_companion_card.dart';

import '../pomodoro_controller.dart';
import '../widgets/mode_label.dart';
import '../widgets/motivation_quote_ticker.dart';
import '../widgets/timer_controls.dart';
import '../widgets/timer_panel.dart';

/// 番茄钟运行态页面内容。
///
/// 展示当前模式、倒计时进度、任务信息、宠物陪伴卡和暂停/放弃控制按钮。
class PomodoroRunningState extends StatelessWidget {
  final PomodoroController controller;

  const PomodoroRunningState({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 运行态整体可滚动，保证小屏幕上控制按钮仍可触达。
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 励志语区：运行时轮播文案，给专注过程提供轻量陪伴。
                const PomodoroMotivationQuoteTicker(),
                const SizedBox(height: 24),
                // 模式标签区：显示当前是专注还是休息，由 controller.currentMode 驱动。
                PomodoroModeLabel(controller: controller),
                Obx(() {
                  if (controller.currentMode.value != 'focus') {
                    return const SizedBox(height: 18);
                  }
                  // 宠物陪伴卡只在专注模式显示，休息模式不展示，避免反馈过载。
                  return Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 18),
                    child: PetFocusCompanionCard(
                      taskTitle: controller.currentTaskTitle.value,
                    ),
                  );
                }),
                // 倒计时进度区：显示剩余时间和环形进度，点击可调整时长。
                PomodoroTimerProgress(controller: controller),
                const SizedBox(height: 24),
                // 当前任务信息区：显示关联任务标题，没有任务时显示自由专注。
                PomodoroRunningTaskInfo(controller: controller),
                const SizedBox(height: 36),
                // 控制按钮区：根据暂停状态切换暂停/继续，并提供放弃入口。
                PomodoroTimerControls(controller: controller),
              ],
            ),
          ),
        );
      },
    );
  }
}
