part of '../pomodoro.dart';

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

class _RunningTaskInfo extends StatelessWidget {
  final PomodoroController controller;

  const _RunningTaskInfo({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final taskTitle = controller.currentTaskTitle.value;
      return Container(
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
          const _TimerSettingsHint(),
        ],
      ),
    );
  }
}

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
          const _TimerSettingsHint(),
        ],
      ),
    );
  }
}

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

class _SettingsTapTarget extends StatelessWidget {
  final PomodoroController controller;
  final Widget child;

  const _SettingsTapTarget({required this.controller, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showSettings(controller),
      child: child,
    );
  }
}

class _StartCircle extends StatelessWidget {
  final PomodoroController controller;

  const _StartCircle({required this.controller});

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

class _TimerProgress extends StatelessWidget {
  final PomodoroController controller;

  const _TimerProgress({required this.controller});

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
