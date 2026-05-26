import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../pomodoro_controller.dart';

void showPomodoroSettingsDialog(PomodoroController controller) {
  Get.dialog(
    AlertDialog(
      title: const Text('番茄钟设置'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
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
