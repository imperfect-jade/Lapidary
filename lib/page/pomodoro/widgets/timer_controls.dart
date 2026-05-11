part of '../pomodoro.dart';

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
