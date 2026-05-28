import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../pomodoro_controller.dart';

/// 今日番茄钟统计区。
///
/// 展示今日已完成专注分钟数和完成番茄数量，数据由 [PomodoroController] 从历史记录初始化并实时更新。
class PomodoroTodayStats extends StatelessWidget {
  final PomodoroController controller;

  const PomodoroTodayStats({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Row(
        // 两张统计卡片横向排列，分别展示专注时长和完成次数。
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statCard('今日专注', '${controller.todayFocusMinutes.value}分钟'),
          _statCard('完成番茄', '${controller.todayPomodoroCount.value}个'),
        ],
      );
    });
  }

  /// 构建单个统计卡片。
  ///
  /// label 是指标名称，value 是已经格式化好的展示值。
  Widget _statCard(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
