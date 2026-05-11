part of '../pomodoro.dart';

class _IdleState extends StatelessWidget {
  final PomodoroController controller;
  final TaskController taskController;

  const _IdleState({required this.controller, required this.taskController});

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
                _TodayStats(controller: controller),
                SizedBox(height: constraints.maxHeight < 620 ? 28 : 56),
                _StartCircle(controller: controller),
                const SizedBox(height: 24),
                _TaskSelector(
                  controller: controller,
                  taskController: taskController,
                ),
                const SizedBox(height: 18),
                const _PomodoroHint(),
              ],
            ),
          ),
        );
      },
    );
  }
}
