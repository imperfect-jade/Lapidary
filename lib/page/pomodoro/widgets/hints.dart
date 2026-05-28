import 'package:flutter/material.dart';

/// 空闲态底部提示文案。
///
/// 告诉用户可以选择任务开始专注，也可以点击计时器调整时长。
class PomodoroHint extends StatelessWidget {
  const PomodoroHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // 提示卡片 UI：作为空闲态辅助说明，不参与任何状态更新。
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

/// 计时器圆盘内的设置提示。
///
/// 出现在空闲态和运行态圆盘中，说明圆盘可点击打开时长设置。
class PomodoroTimerSettingsHint extends StatelessWidget {
  const PomodoroTimerSettingsHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // 小型提示标签 UI：用图标和短文案降低设置入口的隐藏成本。
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
