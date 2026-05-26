part of '../pet.dart';

class _FoodPickerSheet extends StatelessWidget {
  final PetController petController;
  final RewardController rewardController;

  const _FoodPickerSheet({
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
        final species = petController.pet.value?.species ?? PetSpecies.cat;
        final ownedFoods = PetFoodCatalog.foodsForSpecies(
          species,
        ).where((food) => rewardController.foodCount(food.name) > 0).toList();

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '选择食物',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (ownedFoods.isEmpty)
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
