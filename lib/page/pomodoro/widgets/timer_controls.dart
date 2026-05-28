import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../pomodoro_controller.dart';

/// 运行态计时控制按钮组。
///
/// 根据暂停状态切换暂停/继续按钮，并提供放弃当前计时入口。
class PomodoroTimerControls extends StatelessWidget {
  final PomodoroController controller;

  const PomodoroTimerControls({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Row(
        // 控制区 UI：左侧是暂停/继续，右侧是放弃；所有动作委托给 PomodoroController。
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
