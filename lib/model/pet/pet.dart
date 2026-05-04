import 'package:hive/hive.dart';

part 'pet.g.dart';

class PetSpecies {
  static const String cat = 'cat';
}

@HiveType(typeId: 2)
class PetModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String species;

  @HiveField(2)
  String name;

  @HiveField(3)
  int level;

  @HiveField(4)
  int exp;

  @HiveField(5)
  int mood;

  @HiveField(6)
  int hunger;

  @HiveField(7)
  int energy;

  @HiveField(8)
  bool isSleeping;

  @HiveField(9)
  DateTime lastInteractionAt;

  PetModel({
    required this.id,
    required this.species,
    required this.name,
    required this.level,
    required this.exp,
    required this.mood,
    required this.hunger,
    required this.energy,
    required this.isSleeping,
    required this.lastInteractionAt,
  });

  factory PetModel.defaultCat() {
    return PetModel(
      id: 'default_cat',
      species: PetSpecies.cat,
      name: '小云',
      level: 1,
      exp: 0,
      mood: 76,
      hunger: 72,
      energy: 80,
      isSleeping: false,
      lastInteractionAt: DateTime.now(),
    );
  }
}
