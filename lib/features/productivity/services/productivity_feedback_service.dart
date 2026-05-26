import 'package:get/get.dart';
import 'package:todolist/features/productivity/ports/productivity_feedback_ports.dart';
import 'package:todolist/model/pomodoro/pomodoro.dart';
import 'package:todolist/model/task/task.dart';

typedef ProductivitySnackbar = void Function(String title, String message);

class ProductivityFeedbackService {
  ProductivityFeedbackService({
    required this.rewardPort,
    required this.petPort,
    ProductivitySnackbar? showSnackbar,
  }) : showSnackbar = showSnackbar ?? _showGetSnackbar;

  ProductivityFeedbackService.noop()
    : rewardPort = const NoopRewardFeedbackPort(),
      petPort = const NoopPetFeedbackPort(),
      showSnackbar = _noopSnackbar;

  final RewardFeedbackPort rewardPort;
  final PetFeedbackPort petPort;
  final ProductivitySnackbar showSnackbar;

  Future<void> handleTaskCompleted(TaskModel task) async {
    final reward = await rewardPort.awardTaskCompletion(task);
    if (reward <= 0) {
      return;
    }

    showSnackbar('任务完成奖励', '获得 $reward 积分');
    await petPort.celebrateTaskCompletion(task);
  }

  Future<void> handleOverdueTasks(int count, String? title) async {
    if (count <= 0) {
      return;
    }
    await petPort.remindOverdueTasks(count, title);
  }

  void handleFocusStarted(String? taskTitle) {
    petPort.startFocusCompanion(taskTitle: taskTitle);
  }

  Future<void> handlePomodoroRecordSaved(PomodoroModel record) async {
    if (record.type == 'focus') {
      await petPort.applyFocusEnergyCost(record);
    } else if (record.type == 'break' && record.isCompleted) {
      await petPort.restoreBreakEnergy(record);
    }

    if (!record.isCompleted) {
      return;
    }

    final reward = await rewardPort.awardPomodoro(record);
    if (reward <= 0 || record.type != 'focus') {
      return;
    }

    showSnackbar('获得奖励', '专注奖励 +$reward 积分');
    await petPort.celebrateFocusCompletion(record, reward);
  }

  static void _showGetSnackbar(String title, String message) {
    Get.snackbar(title, message, snackPosition: SnackPosition.BOTTOM);
  }

  static void _noopSnackbar(String title, String message) {}
}
