import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../pomodoro_controller.dart';

/// 当前番茄钟模式标签。
///
/// 根据 controller.currentMode 展示“专注中”或“休息中”，并同步切换强调色。
class PomodoroModeLabel extends StatelessWidget {
  final PomodoroController controller;

  const PomodoroModeLabel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isFocus = controller.currentMode.value == 'focus';
      // 模式标签 UI：放在运行态顶部，帮助用户快速确认当前轮次类型。
      return Text(
        isFocus ? '专注中' : '休息中',
        style: TextStyle(
          fontSize: 20,
          color: isFocus ? Colors.red : Colors.green,
        ),
      );
    });
  }
}
