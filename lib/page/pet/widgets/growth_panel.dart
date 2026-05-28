import 'package:flutter/material.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/model/pet/pet.dart';
import 'package:todolist/page/pet/pet_controller.dart';

/// 宠物成长面板，展示昵称、等级和经验进度。
///
/// 面板读取 `PetModel` 的当前值，并通过 `PetController` 获取升级阈值与进度；
/// 它只负责展示，不承担改名或经验计算。
class PetGrowthPanel extends StatelessWidget {
  final PetController controller;
  final PetModel pet;

  const PetGrowthPanel({
    super.key,
    required this.controller,
    required this.pet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部显示宠物名称和等级，改名入口在首页宠物设置 Sheet 中。
          Row(
            children: [
              Expanded(
                child: Text(
                  pet.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: TaskTheme.primaryColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Lv.${pet.level}'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 经验条由 controller.expProgress 驱动，升级公式集中在 PetStateService。
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: controller.expProgress,
              minHeight: 10,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(TaskTheme.appBarColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '经验 ${pet.exp}/${controller.expToNextLevel}',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
