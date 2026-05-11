part of '../pet.dart';

class _RewardShopPanel extends StatefulWidget {
  final PetController petController;
  final RewardController rewardController;

  const _RewardShopPanel({
    required this.petController,
    required this.rewardController,
  });

  @override
  State<_RewardShopPanel> createState() => _RewardShopPanelState();
}

class _RewardShopPanelState extends State<_RewardShopPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final species = widget.petController.pet.value?.species ?? PetSpecies.cat;
      final foods = PetController.foodsForSpecies(species);
      final shopTitle = '${PetController.speciesLabel(species)}食物';

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
