import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/features/pet/services/pet_food_catalog.dart';
import 'package:todolist/model/pet/pet.dart';
import 'package:todolist/page/pet/pet_controller.dart';
import 'package:todolist/page/pet/reward_controller.dart';

import 'food_picker_sheet.dart';

/// 宠物操作栏，提供抚摸、喂食入口和睡眠切换。
///
/// 交互都通过 `PetController` 的公开方法完成；底部库存行读取 `RewardController`
/// 的钱包库存，只展示当前物种可食用且已拥有的食物。
class PetActionBar extends StatelessWidget {
  final PetController controller;
  final PetModel pet;
  final RewardController rewardController;

  const PetActionBar({
    super.key,
    required this.controller,
    required this.pet,
    required this.rewardController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 三个主要动作按钮：抚摸直接生效，喂食打开 Sheet，睡眠按钮根据 pet.isSleeping 切换文案和图标。
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: controller.petCat,
                icon: const Icon(Icons.pan_tool_alt),
                label: const Text('抚摸'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showFoodPicker(),
                icon: const Icon(Icons.rice_bowl),
                label: const Text('喂食'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: controller.toggleSleep,
                icon: Icon(pet.isSleeping ? Icons.wb_sunny : Icons.bedtime),
                label: Text(pet.isSleeping ? '唤醒' : '睡觉'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          // 库存行用于让用户在操作前知道当前物种有哪些可用食物，不负责扣库存。
          child: _FoodInventoryLine(
            rewardController: rewardController,
            pet: pet,
          ),
        ),
      ],
    );
  }

  /// 打开喂食 Sheet 前先让宠物说一句提示文案，实际喂食由 Sheet 中的食物项触发。
  void _showFoodPicker() {
    controller.feed();
    Get.bottomSheet(
      PetFoodPickerSheet(
        petController: controller,
        rewardController: rewardController,
      ),
      isScrollControlled: true,
    );
  }
}

/// 当前宠物物种对应的食物库存摘要。
///
/// 这里用 `Obx` 监听奖励钱包刷新，商城购买或喂食消耗后会自动更新数量。
class _FoodInventoryLine extends StatelessWidget {
  final RewardController rewardController;
  final PetModel pet;

  const _FoodInventoryLine({required this.rewardController, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 食物目录按物种过滤，避免猫狗食物在对方宠物下混用。
      final ownedFoods = PetFoodCatalog.foodsForSpecies(
        pet.species,
      ).where((food) => rewardController.foodCount(food.name) > 0).toList();
      if (ownedFoods.isEmpty) {
        return Text(
          '库存：暂无适合${PetFoodCatalog.speciesLabel(pet.species)}的食物',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        );
      }

      return Wrap(
        spacing: 6,
        runSpacing: 4,
        children: ownedFoods
            .map(
              (food) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${food.name} x${rewardController.foodCount(food.name)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            )
            .toList(),
      );
    });
  }
}
