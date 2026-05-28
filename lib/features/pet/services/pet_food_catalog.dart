import 'package:todolist/features/pet/domain/pet_food.dart';
import 'package:todolist/model/pet/pet.dart';

/// 宠物食物目录服务，集中维护商城食物和物种过滤规则。
///
/// 这里只返回静态目录数据，不访问 UI、Hive 或奖励钱包；库存和购买逻辑由
/// `RewardController` 负责，喂食后的数值变化由 `PetStateService` 负责。
class PetFoodCatalog {
  /// 商城中可购买的全部食物。
  ///
  /// 新增物种或食物时优先扩展这里，并同步确认物种标签和 UI 过滤是否符合预期。
  static const List<PetFood> shopFoods = [
    PetFood(
      species: PetSpecies.cat,
      name: '小鱼干',
      cost: 20,
      hungerBoost: 12,
      moodBoost: 4,
    ),
    PetFood(
      species: PetSpecies.cat,
      name: '猫罐头',
      cost: 45,
      hungerBoost: 28,
      moodBoost: 10,
    ),
    PetFood(
      species: PetSpecies.cat,
      name: '豪华猫饭',
      cost: 80,
      hungerBoost: 45,
      moodBoost: 18,
    ),
    PetFood(
      species: PetSpecies.dog,
      name: '小骨饼干',
      cost: 20,
      hungerBoost: 12,
      moodBoost: 4,
    ),
    PetFood(
      species: PetSpecies.dog,
      name: '鸡肉狗粮',
      cost: 45,
      hungerBoost: 28,
      moodBoost: 10,
    ),
    PetFood(
      species: PetSpecies.dog,
      name: '牛肉能量餐',
      cost: 80,
      hungerBoost: 45,
      moodBoost: 18,
    ),
  ];

  /// 返回指定物种可食用的食物列表，供商城、库存行和喂食 Sheet 复用。
  static List<PetFood> foodsForSpecies(String species) {
    return shopFoods.where((food) => food.species == species).toList();
  }

  /// 将物种编码转换为中文标签，只负责展示，不改变模型中的 species 值。
  static String speciesLabel(String species) {
    return species == PetSpecies.dog ? '小狗' : '小猫';
  }
}
