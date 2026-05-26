import 'dart:math';

import 'package:get/get.dart';
import 'package:todolist/data/repositories/reward_repository.dart';
import 'package:todolist/model/pomodoro/pomodoro.dart';
import 'package:todolist/model/reward/reward_wallet.dart';
import 'package:todolist/model/task/task.dart';
import 'package:todolist/page/pet/pet_controller.dart';

class RewardController extends GetxController {
  RewardController(this.repository);

  static const String walletKey = RewardRepository.walletKey;

  final RewardRepository repository;
  final Rxn<RewardWalletModel> wallet = Rxn<RewardWalletModel>();

  int get points => wallet.value?.points ?? 0;

  int foodCount(String foodName) {
    return wallet.value?.foodInventory[foodName] ?? 0;
  }

  @override
  void onInit() {
    super.onInit();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    wallet.value = await repository.getWallet();
  }

  Future<int> awardPomodoro(PomodoroModel record) async {
    final currentWallet = wallet.value;
    if (currentWallet == null ||
        record.type != 'focus' ||
        !record.isCompleted ||
        currentWallet.rewardedPomodoroIds.contains(record.id)) {
      return 0;
    }

    final focusMinutes = record.actualSeconds ~/ 60;
    final reward = max(5, (focusMinutes ~/ 5) * 5);
    currentWallet.points += reward;
    currentWallet.rewardedPomodoroIds.add(record.id);
    _recordTaskFocus(record);
    await _saveAndNotify();
    return reward;
  }

  Future<int> awardTaskCompletion(TaskModel task) async {
    final currentWallet = wallet.value;
    if (currentWallet == null ||
        currentWallet.rewardedTaskIds.contains(task.id)) {
      return 0;
    }

    final focusSeconds = currentWallet.taskFocusSeconds[task.id] ?? 0;
    final focusMinutes = focusSeconds ~/ 60;
    final reward = 20 + (focusMinutes ~/ 10) * 10;
    currentWallet.points += reward;
    currentWallet.rewardedTaskIds.add(task.id);
    await _saveAndNotify();
    return reward;
  }

  Future<bool> spendPoints(int cost) async {
    final currentWallet = wallet.value;
    if (currentWallet == null || currentWallet.points < cost) {
      return false;
    }

    currentWallet.points -= cost;
    await _saveAndNotify();
    return true;
  }

  Future<bool> buyFood(PetFood food) async {
    final currentWallet = wallet.value;
    if (currentWallet == null || currentWallet.points < food.cost) {
      return false;
    }

    currentWallet.points -= food.cost;
    currentWallet.foodInventory[food.name] =
        (currentWallet.foodInventory[food.name] ?? 0) + 1;
    await _saveAndNotify();
    return true;
  }

  Future<bool> consumeFood(PetFood food) async {
    final currentWallet = wallet.value;
    final count = currentWallet?.foodInventory[food.name] ?? 0;
    if (currentWallet == null || count <= 0) {
      return false;
    }

    if (count == 1) {
      currentWallet.foodInventory.remove(food.name);
    } else {
      currentWallet.foodInventory[food.name] = count - 1;
    }
    await _saveAndNotify();
    return true;
  }

  void _recordTaskFocus(PomodoroModel record) {
    final currentWallet = wallet.value;
    final taskId = record.taskId;
    if (currentWallet == null || taskId == null || taskId.isEmpty) {
      return;
    }

    currentWallet.taskFocusSeconds[taskId] =
        (currentWallet.taskFocusSeconds[taskId] ?? 0) + record.actualSeconds;
  }

  Future<void> _saveAndNotify() async {
    final currentWallet = wallet.value;
    if (currentWallet == null) {
      return;
    }

    await repository.save(currentWallet);
    wallet.refresh();
  }
}
