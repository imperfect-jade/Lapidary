import 'package:hive/hive.dart';
import 'package:todolist/data/hive/box_names.dart';
import 'package:todolist/model/pet/pet.dart';

class PetRepository {
  PetRepository({Box<PetModel>? box})
    : _box = box ?? Hive.box<PetModel>(BoxNames.pets);

  static const String defaultPetKey = 'default_cat';

  final Box<PetModel> _box;

  Future<PetModel> getDefaultPet() async {
    final savedPet = _box.get(defaultPetKey);
    if (savedPet != null) {
      return savedPet;
    }

    final defaultPet = PetModel.defaultCat();
    await putDefaultPet(defaultPet);
    return defaultPet;
  }

  Future<void> putDefaultPet(PetModel pet) {
    return _box.put(pet.id, pet);
  }

  Future<void> save(PetModel pet) {
    return pet.save();
  }
}
