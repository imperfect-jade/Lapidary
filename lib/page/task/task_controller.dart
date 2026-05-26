import 'dart:async';

import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:todolist/data/hive/box_names.dart';
import 'package:todolist/model/task/task.dart';
import 'package:todolist/page/pet/pet_controller.dart';
import 'package:todolist/page/pet/reward_controller.dart';

class TaskController extends GetxController {
  final RxList<TaskModel> taskList = <TaskModel>[].obs;
  final List<TaskModel> _sortedTasks = [];
  final List<TaskModel> _pendingTasks = [];
  final List<TaskModel> _completedTasks = [];
  final Map<int, List<TaskModel>> _tasksByPriority = {};
  final Map<DateTime, List<TaskModel>> _tasksByDay = {};

  late Box<TaskModel> taskBox;
  Timer? _overdueTimer;

  List<TaskModel> get sortedTasks => List.unmodifiable(_sortedTasks);
  List<TaskModel> get completedTasks => List.unmodifiable(_completedTasks);
  List<TaskModel> get pendingTasks => List.unmodifiable(_pendingTasks);
  Map<int, List<TaskModel>> get tasksByPriority => _tasksByPriority;
  Map<DateTime, List<TaskModel>> get tasksByDay => _tasksByDay;

  @override
  void onInit() {
    super.onInit();
    taskBox = Hive.box<TaskModel>(BoxNames.tasks);
    getTasks();
    _startOverdueTimer();
  }

  void getTasks() {
    taskList.value = taskBox.values.toList();
    _rebuildCaches();
    update(['task_list', 'quadrant', 'calendar']);
    unawaited(_applyOverdueMoodPenalties());
  }

  Future<void> addTask(
    String title,
    DateTime deadline, {
    int priority = 3,
    String? description,
    String taskType = TaskType.day,
    String focusTargetPeriod = FocusTargetPeriod.daily,
    int focusTargetMinutes = 0,
  }) async {
    final task = TaskModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      priority: priority,
      deadline: deadline,
      description: description,
      taskType: taskType,
      focusTargetPeriod: focusTargetPeriod,
      focusTargetMinutes: focusTargetMinutes,
    );

    await taskBox.put(task.id, task);
    taskList.add(task);
    _rebuildCaches();
    update(['task_list', 'quadrant', 'calendar']);
  }

  TaskModel? findTaskById(String? id) {
    if (id == null || id.isEmpty) {
      return null;
    }
    for (final task in taskList) {
      if (task.id == id) {
        return task;
      }
    }
    return null;
  }

  Future<void> updateTask(TaskModel task) async {
    await task.save();
    _rebuildCaches();
    update(['task_${task.id}', 'task_list', 'quadrant', 'calendar']);
    await _applyOverdueMoodPenalties();
  }

  Future<void> deleteTask(TaskModel task) async {
    await task.delete();
    taskList.remove(task);
    _rebuildCaches();
    update(['task_list', 'quadrant', 'calendar']);
  }

  Future<void> updateTaskStatus(TaskModel task) async {
    final wasCompleted = task.isCompleted;
    task.isCompleted = !task.isCompleted;
    await task.save();
    if (!wasCompleted && task.isCompleted) {
      if (Get.isRegistered<RewardController>()) {
        final reward = await Get.find<RewardController>().awardTaskCompletion(
          task,
        );
        if (reward > 0) {
          Get.snackbar(
            '任务完成奖励',
            '获得 $reward 积分',
            snackPosition: SnackPosition.BOTTOM,
          );
          if (Get.isRegistered<PetController>()) {
            await Get.find<PetController>().celebrateTaskCompletion(task);
          }
        }
      }
    }
    _rebuildCaches();
    update(['task_${task.id}', 'task_list', 'quadrant', 'calendar']);
    await _applyOverdueMoodPenalties();
  }

  List<TaskModel> tasksForType(String? taskType) {
    if (taskType == null) {
      return sortedTasks;
    }
    return _sortedTasks.where((task) => task.taskType == taskType).toList();
  }

  List<TaskModel> tasksForDay(DateTime date) {
    return _tasksByDay[_dayKey(date)] ?? const [];
  }

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

  void _startOverdueTimer() {
    _overdueTimer?.cancel();
    _overdueTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      unawaited(_applyOverdueMoodPenalties());
    });
  }

  Future<void> _applyOverdueMoodPenalties() async {
    if (!Get.isRegistered<PetController>()) {
      return;
    }

    final now = DateTime.now();
    final overdueTasks = taskList
        .where(
          (task) =>
              !task.isCompleted &&
              !task.overdueMoodPenaltyApplied &&
              task.deadline.isBefore(now),
        )
        .toList();

    if (overdueTasks.isEmpty) {
      return;
    }

    for (final task in overdueTasks) {
      task.overdueMoodPenaltyApplied = true;
      await task.save();
    }

    await Get.find<PetController>().remindOverdueTasks(
      overdueTasks.length,
      overdueTasks.length == 1 ? overdueTasks.first.title : null,
    );
    _rebuildCaches();
    update(['task_list', 'quadrant', 'calendar']);
  }

  @override
  void onClose() {
    _overdueTimer?.cancel();
    super.onClose();
  }
}
