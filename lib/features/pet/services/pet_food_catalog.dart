import 'package:todolist/features/pet/domain/pet_food.dart';
import 'package:todolist/model/pet/pet.dart';

class PetFoodCatalog {
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

  static List<PetFood> foodsForSpecies(String species) {
    return shopFoods.where((food) => food.species == species).toList();
  }

  static String speciesLabel(String species) {
    return species == PetSpecies.dog ? '小狗' : '小猫';
  }
}
