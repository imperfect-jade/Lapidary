import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/features/pet/services/pet_food_catalog.dart';
import 'package:todolist/model/pet/pet.dart';
import 'package:todolist/page/pet/pet_controller.dart';
import 'package:todolist/page/pet/reward_controller.dart';

import 'food_picker_sheet.dart';

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
          child: _FoodInventoryLine(
            rewardController: rewardController,
            pet: pet,
          ),
        ),
      ],
    );
  }

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

class _FoodInventoryLine extends StatelessWidget {
  final RewardController rewardController;
  final PetModel pet;

  const _FoodInventoryLine({required this.rewardController, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
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
