import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:todolist/data/hive/box_names.dart';
import 'package:todolist/data/repositories/task_repository.dart';
import 'package:todolist/features/productivity/ports/productivity_feedback_ports.dart';
import 'package:todolist/features/productivity/services/productivity_feedback_service.dart';
import 'package:todolist/model/pomodoro/pomodoro.dart';
import 'package:todolist/model/task/task.dart';
import 'package:todolist/page/task/task_controller.dart';

void main() {
  late Directory tempDir;
  late Box<TaskModel> taskBox;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'todolist_task_controller_test_',
    );
    Hive.init(tempDir.path);
    _registerAdapter(TaskModelAdapter());
    taskBox = await Hive.openBox<TaskModel>(BoxNames.tasks);
    Get.testMode = true;
  });

  tearDown(() async {
    await taskBox.clear();
    Get.reset();
    Get.testMode = true;
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('applies overdue feedback only once for the same task', () async {
    final feedback = _FeedbackFixture();
    final repository = TaskRepository(box: taskBox);
    final task = _task(
      id: 'overdue-1',
      title: 'Overdue task',
      deadline: DateTime.now().subtract(const Duration(minutes: 5)),
    );
    await repository.put(task);
    final controller = TaskController(repository, feedback.service);
    controller.taskList.add(task);

    await controller.updateTask(task);
    await controller.updateTask(task);

    expect(feedback.pet.overdueCalls, hasLength(1));
    expect(feedback.pet.overdueCalls.single.count, 1);
    expect(feedback.pet.overdueCalls.single.title, 'Overdue task');
    expect(task.overdueMoodPenaltyApplied, isTrue);
    expect(taskBox.get('overdue-1')!.overdueMoodPenaltyApplied, isTrue);

    controller.onClose();
  });

  test('routes first task completion through productivity feedback', () async {
    final feedback = _FeedbackFixture(taskReward: 30);
    final repository = TaskRepository(box: taskBox);
    final task = _task(id: 'task-1');
    await repository.put(task);
    final controller = TaskController(repository, feedback.service);
    controller.taskList.add(task);

    await controller.updateTaskStatus(task);

    expect(feedback.reward.taskAwards, [task]);
    expect(feedback.pet.taskCelebrations, [task]);
    expect(feedback.snackbars.single.title, isNotEmpty);
    expect(feedback.snackbars.single.message, contains('30'));

    controller.onClose();
  });
}

TaskModel _task({
  required String id,
  String title = 'Task',
  DateTime? deadline,
}) {
  return TaskModel(
    id: id,
    title: title,
    deadline: deadline ?? DateTime.now().add(const Duration(days: 1)),
  );
}

class _FeedbackFixture {
  _FeedbackFixture({int taskReward = 0})
    : reward = _FakeRewardFeedbackPort(taskReward: taskReward),
      pet = _FakePetFeedbackPort() {
    service = ProductivityFeedbackService(
      rewardPort: reward,
      petPort: pet,
      showSnackbar: (title, message) {
        snackbars.add(_SnackbarMessage(title, message));
      },
    );
  }

  final _FakeRewardFeedbackPort reward;
  final _FakePetFeedbackPort pet;
  final List<_SnackbarMessage> snackbars = [];
  late final ProductivityFeedbackService service;
}

class _FakeRewardFeedbackPort implements RewardFeedbackPort {
  _FakeRewardFeedbackPort({this.taskReward = 0});

  final int taskReward;
  final List<TaskModel> taskAwards = [];

  @override
  Future<int> awardTaskCompletion(TaskModel task) async {
    taskAwards.add(task);
    return taskReward;
  }

  @override
  Future<int> awardPomodoro(PomodoroModel record) async {
    return 0;
  }
}

class _FakePetFeedbackPort implements PetFeedbackPort {
  final List<TaskModel> taskCelebrations = [];
  final List<_OverdueCall> overdueCalls = [];

  @override
  Future<void> applyFocusEnergyCost(PomodoroModel record) async {}

  @override
  Future<void> celebrateFocusCompletion(
    PomodoroModel record,
    int reward,
  ) async {}

  @override
  Future<void> celebrateTaskCompletion(TaskModel task) async {
    taskCelebrations.add(task);
  }

  @override
  Future<void> remindOverdueTasks(int count, String? title) async {
    overdueCalls.add(_OverdueCall(count, title));
  }

  @override
  Future<void> restoreBreakEnergy(PomodoroModel record) async {}

  @override
  void startFocusCompanion({String? taskTitle}) {}
}

class _SnackbarMessage {
  final String title;
  final String message;

  const _SnackbarMessage(this.title, this.message);
}

class _OverdueCall {
  final int count;
  final String? title;

  const _OverdueCall(this.count, this.title);
}

void _registerAdapter<T>(TypeAdapter<T> adapter) {
  if (!Hive.isAdapterRegistered(adapter.typeId)) {
    Hive.registerAdapter(adapter);
  }
}
