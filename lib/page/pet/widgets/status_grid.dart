import 'package:flutter/material.dart';
import 'package:todolist/model/pet/pet.dart';

/// 宠物三项状态网格，展示心情、饱腹和精力。
///
/// 所有数值都来自当前 `PetModel`，这里只做只读可视化，
/// 状态衰减、恢复和上下限由 `PetStateService` 负责。
class PetStatusGrid extends StatelessWidget {
  final PetModel pet;

  const PetStatusGrid({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 心情会受到抚摸、任务完成、逾期和喂食影响。
        Expanded(
          child: _StatusCard(
            icon: Icons.favorite,
            label: '心情',
            value: pet.mood,
            color: Colors.pinkAccent,
          ),
        ),
        const SizedBox(width: 10),
        // 饱腹主要随时间下降，通过食物补充。
        Expanded(
          child: _StatusCard(
            icon: Icons.restaurant,
            label: '饱腹',
            value: pet.hunger,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 10),
        // 精力在清醒/专注时消耗，睡眠或休息番茄钟会恢复。
        Expanded(
          child: _StatusCard(
            icon: Icons.bedtime,
            label: '精力',
            value: pet.energy,
            color: Colors.indigoAccent,
          ),
        ),
      ],
    );
  }
}

/// 单个状态卡片，负责图标、标签、进度条和数值展示。
class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _StatusCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          // 进度条约定输入值为 0-100，服务层已负责 clamp。
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 7,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 6),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
