import 'package:flutter_test/flutter_test.dart';
import 'package:todolist/features/productivity/ports/productivity_feedback_ports.dart';
import 'package:todolist/features/productivity/services/productivity_feedback_service.dart';
import 'package:todolist/model/pomodoro/pomodoro.dart';
import 'package:todolist/model/task/task.dart';

void main() {
  group('ProductivityFeedbackService', () {
    test(
      'awards task completion and celebrates pet when reward is positive',
      () async {
        final reward = _FakeRewardFeedbackPort(taskReward: 30);
        final pet = _FakePetFeedbackPort();
        final snackbars = <_SnackbarMessage>[];
        final service = _service(reward, pet, snackbars);
        final task = _task();

        await service.handleTaskCompleted(task);

        expect(reward.taskAwards, [task]);
        expect(snackbars.single.title, '任务完成奖励');
        expect(snackbars.single.message, '获得 30 积分');
        expect(pet.taskCelebrations, [task]);
      },
    );

    test('does not show task reward feedback when reward is zero', () async {
      final reward = _FakeRewardFeedbackPort(taskReward: 0);
      final pet = _FakePetFeedbackPort();
      final snackbars = <_SnackbarMessage>[];
      final service = _service(reward, pet, snackbars);
      final task = _task();

      await service.handleTaskCompleted(task);

      expect(reward.taskAwards, [task]);
      expect(snackbars, isEmpty);
      expect(pet.taskCelebrations, isEmpty);
    });

    test('routes overdue tasks to pet feedback', () async {
      final pet = _FakePetFeedbackPort();
      final service = _service(_FakeRewardFeedbackPort(), pet, []);

      await service.handleOverdueTasks(1, '复习');

      expect(pet.overdueCalls.single.count, 1);
      expect(pet.overdueCalls.single.title, '复习');
    });

    test('starts focus companion feedback', () {
      final pet = _FakePetFeedbackPort();
      final service = _service(_FakeRewardFeedbackPort(), pet, []);

      service.handleFocusStarted('英语听力');

      expect(pet.focusCompanionTitles, ['英语听力']);
    });

    test(
      'handles completed focus record with reward and pet feedback',
      () async {
        final reward = _FakeRewardFeedbackPort(pomodoroReward: 25);
        final pet = _FakePetFeedbackPort();
        final snackbars = <_SnackbarMessage>[];
        final service = _service(reward, pet, snackbars);
        final record = _pomodoro(type: 'focus', isCompleted: true);

        await service.handlePomodoroRecordSaved(record);

        expect(pet.focusEnergyRecords, [record]);
        expect(reward.pomodoroAwards, [record]);
        expect(snackbars.single.title, '获得奖励');
        expect(snackbars.single.message, '专注奖励 +25 积分');
        expect(pet.focusCelebrations.single.record, record);
        expect(pet.focusCelebrations.single.reward, 25);
      },
    );

    test('restores break energy without focus reward feedback', () async {
      final reward = _FakeRewardFeedbackPort(pomodoroReward: 25);
      final pet = _FakePetFeedbackPort();
      final snackbars = <_SnackbarMessage>[];
      final service = _service(reward, pet, snackbars);
      final record = _pomodoro(type: 'break', isCompleted: true);

      await service.handlePomodoroRecordSaved(record);

      expect(pet.breakEnergyRecords, [record]);
      expect(snackbars, isEmpty);
      expect(pet.focusCelebrations, isEmpty);
    });
  });
}

ProductivityFeedbackService _service(
  _FakeRewardFeedbackPort reward,
  _FakePetFeedbackPort pet,
  List<_SnackbarMessage> snackbars,
) {
  return ProductivityFeedbackService(
    rewardPort: reward,
    petPort: pet,
    showSnackbar: (title, message) {
      snackbars.add(_SnackbarMessage(title, message));
    },
  );
}

TaskModel _task() {
  return TaskModel(
    id: 'task-1',
    title: '复习',
    deadline: DateTime(2026, 5, 26, 18),
  );
}

PomodoroModel _pomodoro({required String type, required bool isCompleted}) {
  return PomodoroModel(
    id: '$type-${isCompleted ? 'done' : 'open'}',
    taskId: 'task-1',
    taskTitle: '复习',
    durationMinutes: type == 'focus' ? 25 : 5,
    actualSeconds: type == 'focus' ? 1500 : 300,
    startTime: DateTime(2026, 5, 26, 10),
    endTime: DateTime(2026, 5, 26, 10, 25),
    isCompleted: isCompleted,
    type: type,
  );
}

class _FakeRewardFeedbackPort implements RewardFeedbackPort {
  _FakeRewardFeedbackPort({this.taskReward = 0, this.pomodoroReward = 0});

  final int taskReward;
  final int pomodoroReward;
  final List<TaskModel> taskAwards = [];
  final List<PomodoroModel> pomodoroAwards = [];

  @override
  Future<int> awardPomodoro(PomodoroModel record) async {
    pomodoroAwards.add(record);
    return pomodoroReward;
  }

  @override
  Future<int> awardTaskCompletion(TaskModel task) async {
    taskAwards.add(task);
    return taskReward;
  }
}

class _FakePetFeedbackPort implements PetFeedbackPort {
  final List<String?> focusCompanionTitles = [];
  final List<PomodoroModel> focusEnergyRecords = [];
  final List<PomodoroModel> breakEnergyRecords = [];
  final List<_FocusCelebration> focusCelebrations = [];
  final List<TaskModel> taskCelebrations = [];
  final List<_OverdueCall> overdueCalls = [];

  @override
  Future<void> applyFocusEnergyCost(PomodoroModel record) async {
    focusEnergyRecords.add(record);
  }

  @override
  Future<void> celebrateFocusCompletion(
    PomodoroModel record,
    int reward,
  ) async {
    focusCelebrations.add(_FocusCelebration(record, reward));
  }

  @override
  Future<void> celebrateTaskCompletion(TaskModel task) async {
    taskCelebrations.add(task);
  }

  @override
  Future<void> remindOverdueTasks(int count, String? title) async {
    overdueCalls.add(_OverdueCall(count, title));
  }

  @override
  Future<void> restoreBreakEnergy(PomodoroModel record) async {
    breakEnergyRecords.add(record);
  }

  @override
  void startFocusCompanion({String? taskTitle}) {
    focusCompanionTitles.add(taskTitle);
  }
}

class _SnackbarMessage {
  final String title;
  final String message;

  const _SnackbarMessage(this.title, this.message);
}

class _FocusCelebration {
  final PomodoroModel record;
  final int reward;

  const _FocusCelebration(this.record, this.reward);
}

class _OverdueCall {
  final int count;
  final String? title;

  const _OverdueCall(this.count, this.title);
}
