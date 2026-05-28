/// 宠物食物定义，描述商城商品和喂食后对宠物状态的影响。
///
/// 这是纯领域数据，不访问 Hive 或 UI；库存数量保存在奖励钱包中。
class PetFood {
  /// 可食用该食物的宠物物种，例如猫或狗。
  final String species;

  /// 展示给用户的食物名称，也是当前库存 Map 的键。
  final String name;

  /// 商城购买所需积分。
  final int cost;

  /// 喂食后增加的饱腹值。
  final int hungerBoost;

  /// 喂食后增加的心情值。
  final int moodBoost;

  const PetFood({
    required this.species,
    required this.name,
    required this.cost,
    required this.hungerBoost,
    required this.moodBoost,
  });
}
