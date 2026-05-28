import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/features/pet/domain/pet_food.dart';
import 'package:todolist/features/pet/services/pet_food_catalog.dart';
import 'package:todolist/model/pet/pet.dart';
import 'package:todolist/page/pet/pet_controller.dart';
import 'package:todolist/page/pet/reward_controller.dart';

/// 喂食选择底部 Sheet，展示当前宠物物种可食用且已有库存的食物。
///
/// Sheet 只协调一次用户喂食流程：先调用 `PetController.feedWithFood()` 修改宠物状态，
/// 再调用 `RewardController.consumeFood()` 扣库存，两个持久化边界保持独立。
class PetFoodPickerSheet extends StatelessWidget {
  final PetController petController;
  final RewardController rewardController;

  const PetFoodPickerSheet({
    super.key,
    required this.petController,
    required this.rewardController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Obx(() {
        // 物种来自当前宠物状态；宠物未加载时默认按猫展示，避免空指针。
        final species = petController.pet.value?.species ?? PetSpecies.cat;
        // 只展示用户已经拥有的同物种食物，购买入口放在商城面板。
        final ownedFoods = PetFoodCatalog.foodsForSpecies(
          species,
        ).where((food) => rewardController.foodCount(food.name) > 0).toList();

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题区说明当前 Sheet 是一次喂食动作，不处理商城购买。
            const Text(
              '选择食物',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (ownedFoods.isEmpty)
              // 空库存状态提示用户回到宠物商城兑换食物。
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: Text(
                    '还没有适合当前宠物的食物，先去商城兑换吧',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              // 每个食物项展示库存、饱腹和心情增益，点击后进入 _useFood 流程。
              ...ownedFoods.map(
                (food) => ListTile(
                  leading: const Icon(Icons.restaurant, color: Colors.orange),
                  title: Text(food.name),
                  subtitle: Text(
                    '拥有 ${rewardController.foodCount(food.name)} 份 · +${food.hungerBoost} 饱腹  +${food.moodBoost} 心情',
                  ),
                  onTap: () => _useFood(food),
                ),
              ),
            const SizedBox(height: 8),
          ],
        );
      }),
    );
  }

  /// 执行一次喂食：库存校验、宠物状态更新、库存扣减和关闭 Sheet。
  ///
  /// 先喂食再扣库存是为了沿用现有行为；如果扣库存失败会提示库存变化，
  /// 不在这里回滚宠物状态，后续若要事务化可在 Repository 层统一处理。
  Future<void> _useFood(PetFood food) async {
    if (rewardController.foodCount(food.name) <= 0) {
      Get.snackbar('没有库存', '先去商城兑换这个食物吧', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final fed = await petController.feedWithFood(food);
    if (!fed) {
      Get.snackbar(
        '喂食失败',
        '宠物状态还没准备好，请稍后再试',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final consumed = await rewardController.consumeFood(food);
    if (!consumed) {
      Get.snackbar('库存已变化', '这个食物已经没有库存了', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    Get.back();
  }
}
