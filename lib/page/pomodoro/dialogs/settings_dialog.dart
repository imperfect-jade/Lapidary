import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../pomodoro_controller.dart';

/// 显示番茄钟时长设置弹窗。
///
/// 弹窗只更新 [PomodoroController] 中的专注/休息时长，不直接写入 Hive，也不影响已运行中的计时器。
void showPomodoroSettingsDialog(PomodoroController controller) {
  Get.dialog(
    // 设置弹窗 UI：分别选择专注时长和休息时长，关闭后设置会用于下一轮计时。
    AlertDialog(
      title: const Text('番茄钟设置'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            // 专注时长选择区：改变 controller.focusDuration。
            children: [
              const Text('专注时长：'),
              Obx(
                () => DropdownButton<int>(
                  value: controller.focusDuration.value,
                  items: [15, 25, 30, 45, 60]
                      .map(
                        (v) => DropdownMenuItem(value: v, child: Text('$v分钟')),
                      )
                      .toList(),
                  onChanged: (v) => controller.focusDuration.value = v ?? 25,
                ),
              ),
            ],
          ),
          Row(
            // 休息时长选择区：改变 controller.breakDuration。
            children: [
              const Text('休息时长：'),
              Obx(
                () => DropdownButton<int>(
                  value: controller.breakDuration.value,
                  items: [5, 10, 15]
                      .map(
                        (v) => DropdownMenuItem(value: v, child: Text('$v分钟')),
                      )
                      .toList(),
                  onChanged: (v) => controller.breakDuration.value = v ?? 5,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('完成')),
      ],
    ),
  );
}
