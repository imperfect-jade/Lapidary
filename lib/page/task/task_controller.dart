//待办任务控制器
import 'package:get/get.dart';
import 'package:todolist/model/task/task.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:todolist/page/pet/reward_controller.dart';

class TaskController extends GetxController {
  final RxList<TaskModel> taskList = <TaskModel>[].obs;
  final List<TaskModel> _sortedTasks = [];
  final List<TaskModel> _pendingTasks = [];
  final List<TaskModel> _completedTasks = [];
  final Map<int, List<TaskModel>> _tasksByPriority = {};
  final Map<DateTime, List<TaskModel>> _tasksByDay = {};

  late Box<TaskModel> taskBox;

  List<TaskModel> get sortedTasks => List.unmodifiable(_sortedTasks);
  List<TaskModel> get completedTasks => List.unmodifiable(_completedTasks);
  List<TaskModel> get pendingTasks => List.unmodifiable(_pendingTasks);
  Map<int, List<TaskModel>> get tasksByPriority => _tasksByPriority;
  Map<DateTime, List<TaskModel>> get tasksByDay => _tasksByDay;

  //初始化
  @override
  void onInit() {
    super.onInit();
    //打开数据库
    taskBox = Hive.box<TaskModel>('tasks');
    //获取所有任务
    getTasks();
  }

  //获取所有任务
  void getTasks() {
    taskList.value = taskBox.values.toList();
    _rebuildCaches();
    update(['task_list', 'quadrant', 'calendar']);
  }

  //添加任务
  Future<void> addTask(
    String title,
    DateTime deadline, {
    int priority = 3,
    String? description,
  }) async {
    final task = TaskModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // 用时间戳作为唯一ID
      title: title,
      priority: priority,
      deadline: deadline,
      description: description,
    );

    await taskBox.put(task.id, task); // 存入Hive
    taskList.add(task); // 更新响应式列表
    _rebuildCaches();
    update(['task_list', 'quadrant', 'calendar']);
  }

  //更新任务
  Future<void> updateTask(TaskModel task) async {
    await task.save(); // 存入Hive
    _rebuildCaches();
    update(['task_${task.id}', 'task_list', 'quadrant', 'calendar']);
  }

  //删除任务
  Future<void> deleteTask(TaskModel task) async {
    await task.delete();
    taskList.remove(task);
    _rebuildCaches();
    update(['task_list', 'quadrant', 'calendar']);
  }

  //修改任务状态
  Future<void> updateTaskStatus(TaskModel task) async {
    final wasCompleted = task.isCompleted;
    task.isCompleted = !task.isCompleted;
    await task.save(); // 存入Hive
    if (!wasCompleted &&
        task.isCompleted &&
        Get.isRegistered<RewardController>()) {
      final reward = await Get.find<RewardController>().awardTaskCompletion(
        task,
      );
      if (reward > 0) {
        Get.snackbar(
          '任务完成奖励',
          '获得 $reward 积分',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
    _rebuildCaches();
    update(['task_${task.id}', 'quadrant', 'calendar']);
  }

  // 按日期获取任务，供日历 marker 使用
  List<TaskModel> tasksForDay(DateTime date) {
    return _tasksByDay[_dayKey(date)] ?? const [];
  }

  // 获取某个优先级的待办任务，供四象限使用
  List<TaskModel> pendingTasksForPriority(int priority) {
    return _tasksByPriority[priority] ?? const [];
  }

  void _rebuildCaches() {
    _sortedTasks
      ..clear()
      ..addAll(taskList)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _pendingTasks
      ..clear()
      ..addAll(taskList.where((task) => !task.isCompleted));

    _completedTasks
      ..clear()
      ..addAll(taskList.where((task) => task.isCompleted));

    _tasksByPriority
      ..clear()
      ..addEntries(
        List.generate(4, (index) => MapEntry(index + 1, <TaskModel>[])),
      );
    for (final task in _pendingTasks) {
      (_tasksByPriority[task.priority] ??= <TaskModel>[]).add(task);
    }

    _tasksByDay.clear();
    for (final task in taskList) {
      final key = _dayKey(task.deadline);
      (_tasksByDay[key] ??= <TaskModel>[]).add(task);
    }
  }

  DateTime _dayKey(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
