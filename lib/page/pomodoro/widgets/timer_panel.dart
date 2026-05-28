import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../dialogs/settings_dialog.dart';
import '../pomodoro_controller.dart';
import 'hints.dart';

/// 计时器圆形面板外壳。
///
/// 根据当前是否为专注模式切换强调色，内部 child 负责显示具体时间文字。
class _TimerPanel extends StatelessWidget {
  final Widget child;
  final bool isFocus;

  const _TimerPanel({required this.child, required this.isFocus});

  @override
  Widget build(BuildContext context) {
    final color = isFocus
        ? const Color.fromARGB(255, 239, 116, 116)
        : const Color.fromARGB(255, 89, 174, 118);
    return Container(
      // 圆形视觉容器：用于空闲态开始圆盘和运行态进度圆盘的共同底座。
      width: 242,
      height: 242,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.35), width: 5),
      ),
      child: Center(child: child),
    );
  }
}

/// 运行态当前任务信息条。
///
/// 由 controller.currentTaskTitle 驱动，有关联任务时显示标题，否则显示自由专注。
class PomodoroRunningTaskInfo extends StatelessWidget {
  final PomodoroController controller;

  const PomodoroRunningTaskInfo({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final taskTitle = controller.currentTaskTitle.value;
      return Container(
        // 任务信息条 UI：放在计时器下方，限制一行避免长标题撑开布局。
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          taskTitle == null ? '自由专注' : '当前任务：$taskTitle',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            color: Color.fromARGB(255, 76, 96, 112),
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    });
  }
}

/// 空闲态计时器中心文字。
///
/// 显示下一轮专注的预设时长，并提示用户点击计时器可调整设置。
class _IdleTimerLabel extends StatelessWidget {
  final PomodoroController controller;

  const _IdleTimerLabel({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${controller.focusDuration.value.toString().padLeft(2, '0')}:00',
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 44, 58, 70),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '专注 ${controller.focusDuration.value} 分钟',
            style: const TextStyle(
              fontSize: 14,
              color: Color.fromARGB(255, 98, 118, 136),
            ),
          ),
          const SizedBox(height: 12),
          const PomodoroTimerSettingsHint(),
        ],
      ),
    );
  }
}

/// 运行态计时器中心文字。
///
/// 显示实时剩余时间和当前模式，颜色随专注/休息切换。
class _RunningTimerLabel extends StatelessWidget {
  final PomodoroController controller;

  const _RunningTimerLabel({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            controller.formattedTime,
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 44, 58, 70),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.currentMode.value == 'focus' ? '专注中' : '休息中',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: controller.currentMode.value == 'focus'
                  ? Colors.red
                  : Colors.green,
            ),
          ),
          const SizedBox(height: 12),
          const PomodoroTimerSettingsHint(),
        ],
      ),
    );
  }
}

/// 运行态环形进度条。
///
/// 进度由 [PomodoroController.progress] 提供，中心 child 通常是圆形计时器面板。
class _TimerProgressRing extends StatelessWidget {
  final PomodoroController controller;
  final Widget child;

  const _TimerProgressRing({required this.controller, required this.child});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isFocus = controller.currentMode.value == 'focus';
      final color = isFocus ? Colors.red : Colors.green;
      return SizedBox(
        // 外层环形进度：显示当前轮次已经经过的比例。
        width: 258,
        height: 258,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 258,
              height: 258,
              child: CircularProgressIndicator(
                value: controller.progress,
                strokeWidth: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.78),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            child,
          ],
        ),
      );
    });
  }
}

/// 计时器设置点击热区。
///
/// 包裹空闲态和运行态计时器，让用户点击圆盘即可打开时长设置。
class _SettingsTapTarget extends StatelessWidget {
  final PomodoroController controller;
  final Widget child;

  const _SettingsTapTarget({required this.controller, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showPomodoroSettingsDialog(controller),
      child: child,
    );
  }
}

/// 空闲态开始圆盘。
///
/// 展示当前专注时长设置，点击圆盘打开设置弹窗；真正开始计时由任务选择入口触发。
class PomodoroStartCircle extends StatelessWidget {
  final PomodoroController controller;

  const PomodoroStartCircle({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isFocus = controller.currentMode.value == 'focus';
      return _SettingsTapTarget(
        controller: controller,
        child: _TimerPanel(
          isFocus: isFocus,
          child: _IdleTimerLabel(controller: controller),
        ),
      );
    });
  }
}

/// 运行态倒计时进度圆盘。
///
/// 展示剩余时间和进度，点击圆盘仍可打开设置弹窗调整后续轮次时长。
class PomodoroTimerProgress extends StatelessWidget {
  final PomodoroController controller;

  const PomodoroTimerProgress({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isFocus = controller.currentMode.value == 'focus';
      return _SettingsTapTarget(
        controller: controller,
        child: _TimerProgressRing(
          controller: controller,
          child: _TimerPanel(
            isFocus: isFocus,
            child: _RunningTimerLabel(controller: controller),
          ),
        ),
      );
    });
  }
}
