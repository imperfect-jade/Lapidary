part of '../pomodoro.dart';

class _PomodoroHint extends StatelessWidget {
  const _PomodoroHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        '点击任务开始专注，点击计时器调整时长',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: Color.fromARGB(255, 92, 118, 140),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _TimerSettingsHint extends StatelessWidget {
  const _TimerSettingsHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app, size: 14, color: Colors.grey),
          SizedBox(width: 4),
          Text('点击计时器设置时长', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
