import 'package:flutter/material.dart';
import 'package:todolist/constants/theme.dart';

/// 任务类型小徽标，用于在任务卡片标题旁快速识别日/周/月任务。
class TaskBadge extends StatelessWidget {
  final String label;

  const TaskBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      // 任务类型徽标 UI：使用浅色背景和短文本，适合放在标题行末尾。
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: TaskTheme.appBarColor.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// 任务卡片中的辅助信息片段，例如截止时间、优先级和专注目标。
class TaskInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const TaskInfoChip({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? Colors.grey[600]!;
    return Row(
      // 信息片段 UI：图标和文字保持紧凑布局，适合在任务卡片摘要区换行排列。
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: foreground),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 12, color: foreground)),
      ],
    );
  }
}
