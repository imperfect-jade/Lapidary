import 'package:todolist/model/pomodoro/pomodoro.dart';
import 'package:todolist/model/task/task.dart';

abstract class RewardFeedbackPort {
  Future<int> awardTaskCompletion(TaskModel task);

  Future<int> awardPomodoro(PomodoroModel record);
}

abstract class PetFeedbackPort {
  void startFocusCompanion({String? taskTitle});

  Future<void> applyFocusEnergyCost(PomodoroModel record);

  Future<void> restoreBreakEnergy(PomodoroModel record);

  Future<void> celebrateFocusCompletion(PomodoroModel record, int reward);

  Future<void> celebrateTaskCompletion(TaskModel task);

  Future<void> remindOverdueTasks(int count, String? title);
}

class NoopRewardFeedbackPort implements RewardFeedbackPort {
  const NoopRewardFeedbackPort();

  @override
  Future<int> awardTaskCompletion(TaskModel task) async {
    return 0;
  }

  @override
  Future<int> awardPomodoro(PomodoroModel record) async {
    return 0;
  }
}

class NoopPetFeedbackPort implements PetFeedbackPort {
  const NoopPetFeedbackPort();

  @override
  Future<void> applyFocusEnergyCost(PomodoroModel record) async {}

  @override
  Future<void> celebrateFocusCompletion(
    PomodoroModel record,
    int reward,
  ) async {}

  @override
  Future<void> celebrateTaskCompletion(TaskModel task) async {}

  @override
  Future<void> remindOverdueTasks(int count, String? title) async {}

  @override
  Future<void> restoreBreakEnergy(PomodoroModel record) async {}

  @override
  void startFocusCompanion({String? taskTitle}) {}
}
