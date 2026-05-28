import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/features/pet/domain/pet_food.dart';
import 'package:todolist/features/pet/services/pet_food_catalog.dart';
import 'package:todolist/model/pet/pet.dart';
import 'package:todolist/page/pet/pet_controller.dart';
import 'package:todolist/page/pet/reward_controller.dart';

/// 宠物奖励商城，展示积分余额和当前物种可购买的食物。
///
/// 商城只消费 `RewardController` 的钱包数据，不直接修改宠物状态；
/// 购买后的食物会进入库存，真正喂食仍通过操作栏的喂食 Sheet 完成。
class PetRewardShopPanel extends StatefulWidget {
  final PetController petController;
  final RewardController rewardController;

  const PetRewardShopPanel({
    super.key,
    required this.petController,
    required this.rewardController,
  });

  @override
  State<PetRewardShopPanel> createState() => _RewardShopPanelState();
}

class _RewardShopPanelState extends State<PetRewardShopPanel> {
  // 折叠状态只影响本面板展示，不写入持久化。
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 按当前宠物物种切换商城目录，确保猫狗食物不会混在一起。
      final species = widget.petController.pet.value?.species ?? PetSpecies.cat;
      final foods = PetFoodCatalog.foodsForSpecies(species);
      final shopTitle = '${PetFoodCatalog.speciesLabel(species)}食物';

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
            // 商城头部显示积分余额、当前物种标签和展开/收起按钮。
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.stars, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '奖励积分：${widget.rewardController.points}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          '宠物商城',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          shopTitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              // 展开后展示食物项，购买按钮状态由积分余额响应式决定。
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  const SizedBox(height: 12),
                  ...foods.map(
                    (food) => _FoodShopItem(
                      food: food,
                      rewardController: widget.rewardController,
                    ),
                  ),
                ],
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 180),
            ),
          ],
        ),
      );
    });
  }
}

/// 商城里的单个食物商品。
///
/// 商品项展示价格、增益和已有库存；点击购买只调用 `RewardController.buyFood()`。
class _FoodShopItem extends StatelessWidget {
  final PetFood food;
  final RewardController rewardController;

  const _FoodShopItem({required this.food, required this.rewardController});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TaskTheme.primaryColor.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // 食物图标目前使用通用图标，后续可替换为像素食物素材。
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.restaurant, color: Colors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 商品信息来自 PetFoodCatalog，避免 UI 层散落食物数值。
                Text(
                  food.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '+${food.hungerBoost} 饱腹  +${food.moodBoost} 心情',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Obx(
                  // 库存数量随钱包刷新自动变化，购买成功后无需手动 setState。
                  () => Text(
                    '拥有 ${rewardController.foodCount(food.name)} 份',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Obx(() {
            // 积分不足时按钮仍展示价格，但点击会走失败提示，不直接消费。
            final canBuy = rewardController.points >= food.cost;
            return ElevatedButton(
              onPressed: () => _buyFood(canBuy),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                backgroundColor: canBuy ? null : Colors.grey[300],
                foregroundColor: canBuy ? null : Colors.grey[600],
              ),
              child: Text('${food.cost}积分'),
            );
          }),
        ],
      ),
    );
  }

  /// 购买当前食物并持久化钱包。
  ///
  /// 这里不修改宠物饱腹/心情，只把食物放入库存；用户仍需手动喂食。
  Future<void> _buyFood(bool canBuy) async {
    if (!canBuy) {
      Get.snackbar('积分不足', '再完成一些专注或任务吧', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final success = await rewardController.buyFood(food);
    if (!success) {
      Get.snackbar('积分不足', '再完成一些专注或任务吧', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    Get.snackbar(
      '已购买',
      '${food.name} 已放入库存',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
