import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../pomodoro_controller.dart';

class PomodoroModeLabel extends StatelessWidget {
  final PomodoroController controller;

  const PomodoroModeLabel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isFocus = controller.currentMode.value == 'focus';
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
