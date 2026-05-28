import 'dart:async';

import 'package:get/get.dart';
import 'package:todolist/data/repositories/task_repository.dart';
import 'package:todolist/features/productivity/services/productivity_feedback_service.dart';
import 'package:todolist/model/task/task.dart';

/// 待办任务业务控制器。
///
/// Controller 负责状态缓存、页面刷新和跨模块反馈编排；Hive 读写边界保留在 [TaskRepository]。
class TaskController extends GetxController {
  TaskController(
    this.repository, [
    ProductivityFeedbackService? feedbackService,
  ]) : feedbackService = feedbackService ?? ProductivityFeedbackService.noop();

  final TaskRepository repository;
  final ProductivityFeedbackService feedbackService;

  /// 原始任务列表，作为页面响应式数据源；派生查询统一由缓存列表提供。
  final RxList<TaskModel> taskList = <TaskModel>[].obs;

  // 以下缓存服务于任务页、四象限和日历，避免多个页面重复排序或分组。
  final List<TaskModel> _sortedTasks = [];
  final List<TaskModel> _pendingTasks = [];
  final List<TaskModel> _completedTasks = [];
  final Map<int, List<TaskModel>> _tasksByPriority = {};
  final Map<DateTime, List<TaskModel>> _tasksByDay = {};

  Timer? _overdueTimer;

  List<TaskModel> get sortedTasks => List.unmodifiable(_sortedTasks);
  List<TaskModel> get completedTasks => List.unmodifiable(_completedTasks);
  List<TaskModel> get pendingTasks => List.unmodifiable(_pendingTasks);
  Map<int, List<TaskModel>> get tasksByPriority => _tasksByPriority;
  Map<DateTime, List<TaskModel>> get tasksByDay => _tasksByDay;

  @override
  void onInit() {
    super.onInit();
    // Controller 初始化时先加载本地任务，再启动逾期轮询。
    getTasks();
    _startOverdueTimer();
  }

  /// 从 Repository 读取全部任务，并刷新任务页、四象限和日历所需缓存。
  void getTasks() {
    taskList.value = repository.getAll();
    _rebuildCaches();
    // 任务数据会被任务页、四象限和日历共同消费，变更后需要同步刷新这些视图。
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
    // 创建任务模型：id 使用当前微秒时间戳，避免本地新增时发生重复。
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

    await repository.put(task);
    taskList.add(task);
    _rebuildCaches();
    // 新增任务可能同时影响任务列表、四象限分布和日历日程。
    update(['task_list', 'quadrant', 'calendar']);
  }

  /// 根据任务 id 查找当前内存中的任务。
  ///
  /// 主要供番茄钟等模块按关联 id 读取任务快照；找不到时返回 null。
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

  /// 保存已有任务的修改，并同步刷新所有依赖任务数据的页面。
  ///
  /// 保存后会重新检查逾期状态，确保编辑截止时间后提醒状态及时更新。
  Future<void> updateTask(TaskModel task) async {
    await repository.save(task);
    _rebuildCaches();
    // 单任务和聚合视图都需要刷新，保证详情编辑后各入口显示一致。
    update(['task_${task.id}', 'task_list', 'quadrant', 'calendar']);
    await _applyOverdueMoodPenalties();
  }

  /// 删除任务并刷新任务列表、四象限和日历。
  ///
  /// 删除动作只移除任务本身，不在这里处理番茄钟历史记录等跨模块数据。
  Future<void> deleteTask(TaskModel task) async {
    await repository.delete(task);
    taskList.remove(task);
    _rebuildCaches();
    update(['task_list', 'quadrant', 'calendar']);
  }

  /// 切换任务完成状态。
  ///
  /// 从未完成切换为完成时会触发积分奖励和宠物反馈；取消完成只更新状态。
  Future<void> updateTaskStatus(TaskModel task) async {
    final wasCompleted = task.isCompleted;
    task.isCompleted = !task.isCompleted;
    await repository.save(task);
    if (!wasCompleted && task.isCompleted) {
      // 只有首次从未完成切到完成时发放奖励，取消完成不触发反向奖励流程。
      await feedbackService.handleTaskCompleted(task);
    }
    _rebuildCaches();
    update(['task_${task.id}', 'task_list', 'quadrant', 'calendar']);
    await _applyOverdueMoodPenalties();
  }

  /// 按任务类型筛选任务。
  ///
  /// 传入 null 表示不过滤，返回按创建时间倒序排列的全部任务。
  List<TaskModel> tasksForType(String? taskType) {
    if (taskType == null) {
      return sortedTasks;
    }
    return _sortedTasks.where((task) => task.taskType == taskType).toList();
  }

  /// 获取某一天的任务列表，用于日历按日期展示任务。
  List<TaskModel> tasksForDay(DateTime date) {
    return _tasksByDay[_dayKey(date)] ?? const [];
  }

  /// 获取某个优先级下未完成任务，用于四象限页面分组展示。
  List<TaskModel> pendingTasksForPriority(int priority) {
    return _tasksByPriority[priority] ?? const [];
  }

  /// 重建全部派生缓存。
  ///
  /// 缓存包括任务页排序列表、完成/未完成列表、四象限优先级索引和日历日期索引。
  void _rebuildCaches() {
    // 每次任务集合变化后统一重建派生缓存，保证各页面查询口径一致。
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
    // 归一化到当天 00:00，避免相同日期不同时间无法作为同一个日历 key。
    return DateTime(date.year, date.month, date.day);
  }

  /// 启动逾期任务轮询。
  ///
  /// 轮询只负责发现新逾期任务，实际反馈和持久化由 [_applyOverdueMoodPenalties] 完成。
  void _startOverdueTimer() {
    _overdueTimer?.cancel();
    // 逾期检查按分钟轮询，避免页面停留时错过宠物提醒。
    _overdueTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      unawaited(_applyOverdueMoodPenalties());
    });
  }

  /// 对新逾期任务触发一次性宠物反馈。
  ///
  /// 每个任务通过 `overdueMoodPenaltyApplied` 标记已处理，避免每分钟重复提醒。
  Future<void> _applyOverdueMoodPenalties() async {
    final now = DateTime.now();
    final overdueTasks = taskList
        .where(
          (task) =>
              !task.isCompleted &&
              // overdueMoodPenaltyApplied 是一次性护栏，避免同一任务重复触发逾期反馈。
              !task.overdueMoodPenaltyApplied &&
              task.deadline.isBefore(now),
        )
        .toList();

    if (overdueTasks.isEmpty) {
      return;
    }

    for (final task in overdueTasks) {
      task.overdueMoodPenaltyApplied = true;
      await repository.save(task);
    }

    await feedbackService.handleOverdueTasks(
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
