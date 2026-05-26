import 'package:hive/hive.dart';
import 'package:todolist/data/hive/box_names.dart';
import 'package:todolist/model/task/task.dart';

class TaskRepository {
  TaskRepository({Box<TaskModel>? box})
    : _box = box ?? Hive.box<TaskModel>(BoxNames.tasks);

  final Box<TaskModel> _box;

  List<TaskModel> getAll() {
    return _box.values.toList();
  }

  Future<void> put(TaskModel task) {
    return _box.put(task.id, task);
  }

  Future<void> save(TaskModel task) {
    return task.save();
  }

  Future<void> delete(TaskModel task) {
    return task.delete();
  }
}
