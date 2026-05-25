part of '../pomodoro.dart';

class _RunningState extends StatelessWidget {
  final PomodoroController controller;

  const _RunningState({required this.controller});

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
                const _MotivationQuoteTicker(),
                const SizedBox(height: 24),
                _ModeLabel(controller: controller),
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
                _TimerProgress(controller: controller),
                const SizedBox(height: 24),
                _RunningTaskInfo(controller: controller),
                const SizedBox(height: 36),
                _TimerControls(controller: controller),
              ],
            ),
          ),
        );
      },
    );
  }
}
