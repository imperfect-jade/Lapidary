import 'package:hive/hive.dart';
import 'package:todolist/data/hive/box_names.dart';
import 'package:todolist/model/pet_diary/pet_diary.dart';

class PetDiaryRepository {
  PetDiaryRepository({Box<PetDiaryModel>? box})
    : _box = box ?? Hive.box<PetDiaryModel>(BoxNames.petDiaries);

  final Box<PetDiaryModel> _box;

  List<PetDiaryModel> getAll() {
    return _box.values.toList();
  }

  PetDiaryModel? getById(String id) {
    return _box.get(id);
  }

  Future<void> put(PetDiaryModel diary) {
    return _box.put(diary.id, diary);
  }

  List<PetDiaryModel> latestFirst() {
    return getAll()..sort((a, b) => b.date.compareTo(a.date));
  }
}
