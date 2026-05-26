import 'package:hive/hive.dart';
import 'package:todolist/data/hive/box_names.dart';
import 'package:todolist/model/schedule/schedule.dart';

class ScheduleRepository {
  ScheduleRepository({Box<ScheduleSemesterModel>? box})
    : _box = box ?? Hive.box<ScheduleSemesterModel>(BoxNames.scheduleSemesters);

  final Box<ScheduleSemesterModel> _box;

  List<ScheduleSemesterModel> getAll() {
    return _box.values.toList();
  }

  Future<void> put(ScheduleSemesterModel semester) {
    return _box.put(semester.id, semester);
  }
}
