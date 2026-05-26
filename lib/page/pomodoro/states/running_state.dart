import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/page/pet/widgets/pet_focus_companion_card.dart';

import '../pomodoro_controller.dart';
import '../widgets/mode_label.dart';
import '../widgets/motivation_quote_ticker.dart';
import '../widgets/timer_controls.dart';
import '../widgets/timer_panel.dart';

class PomodoroRunningState extends StatelessWidget {
  final PomodoroController controller;

  const PomodoroRunningState({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const PomodoroMotivationQuoteTicker(),
                const SizedBox(height: 24),
                PomodoroModeLabel(controller: controller),
                Obx(() {
                  if (controller.currentMode.value != 'focus') {
                    return const SizedBox(height: 18);
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 18),
                    child: PetFocusCompanionCard(
                      taskTitle: controller.currentTaskTitle.value,
                    ),
                  );
                }),
                PomodoroTimerProgress(controller: controller),
                const SizedBox(height: 24),
                PomodoroRunningTaskInfo(controller: controller),
                const SizedBox(height: 36),
                PomodoroTimerControls(controller: controller),
              ],
            ),
          ),
        );
      },
    );
  }
}
