import 'package:hive/hive.dart';
import 'package:todolist/data/hive/box_names.dart';
import 'package:todolist/model/pomodoro/pomodoro.dart';

class PomodoroRepository {
  PomodoroRepository({Box<PomodoroModel>? box})
    : _box = box ?? Hive.box<PomodoroModel>(BoxNames.pomodoros);

  final Box<PomodoroModel> _box;

  List<PomodoroModel> getAll() {
    return _box.values.toList();
  }

  Future<void> put(PomodoroModel record) {
    return _box.put(record.id, record);
  }
}
