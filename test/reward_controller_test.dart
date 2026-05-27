import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:todolist/data/hive/box_names.dart';
import 'package:todolist/data/repositories/reward_repository.dart';
import 'package:todolist/features/pet/domain/pet_food.dart';
import 'package:todolist/model/pomodoro/pomodoro.dart';
import 'package:todolist/model/reward/reward_wallet.dart';
import 'package:todolist/model/task/task.dart';
import 'package:todolist/page/pet/reward_controller.dart';

void main() {
  late Directory tempDir;
  late Box<RewardWalletModel> walletBox;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'todolist_reward_controller_test_',
    );
    Hive.init(tempDir.path);
    _registerAdapter(RewardWalletModelAdapter());
    walletBox = await Hive.openBox<RewardWalletModel>(BoxNames.rewardWallet);
  });

  tearDown(() async {
    await walletBox.clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('awards task completion once and includes focus bonus', () async {
    final controller = await _controller(
      wallet: RewardWalletModel(
        points: 10,
        rewardedPomodoroIds: <String>[],
        rewardedTaskIds: <String>[],
        taskFocusSeconds: <String, int>{'task-1': 20 * 60},
        foodInventory: <String, int>{},
      ),
    );
    final task = _task(id: 'task-1');

    final firstReward = await controller.awardTaskCompletion(task);
    final secondReward = await controller.awardTaskCompletion(task);

    expect(firstReward, 40);
    expect(secondReward, 0);
    expect(controller.points, 50);
    expect(controller.wallet.value!.rewardedTaskIds, ['task-1']);
    expect((await _repository().getWallet()).points, 50);
  });

  test('awards completed focus pomodoro once and records task focus', () async {
    final controller = await _controller();
    final record = _pomodoro(
      id: 'pomodoro-1',
      taskId: 'task-1',
      type: 'focus',
      isCompleted: true,
      actualSeconds: 25 * 60,
    );

    final firstReward = await controller.awardPomodoro(record);
    final secondReward = await controller.awardPomodoro(record);

    expect(firstReward, 25);
    expect(secondReward, 0);
    expect(controller.points, 25);
    expect(controller.wallet.value!.rewardedPomodoroIds, ['pomodoro-1']);
    expect(controller.wallet.value!.taskFocusSeconds['task-1'], 25 * 60);
  });

  test('does not reward unfinished focus or break records', () async {
    final controller = await _controller();

    final unfinishedReward = await controller.awardPomodoro(
      _pomodoro(id: 'unfinished', type: 'focus', isCompleted: false),
    );
    final breakReward = await controller.awardPomodoro(
      _pomodoro(id: 'break', type: 'break', isCompleted: true),
    );

    expect(unfinishedReward, 0);
    expect(breakReward, 0);
    expect(controller.points, 0);
    expect(controller.wallet.value!.rewardedPomodoroIds, isEmpty);
  });

  test('buys food by spending points and adding inventory', () async {
    final controller = await _controller(
      wallet: RewardWalletModel(
        points: 30,
        rewardedPomodoroIds: <String>[],
        rewardedTaskIds: <String>[],
        taskFocusSeconds: <String, int>{},
        foodInventory: <String, int>{},
      ),
    );
    const food = PetFood(
      species: 'cat',
      name: 'fish',
      cost: 20,
      hungerBoost: 12,
      moodBoost: 4,
    );

    final bought = await controller.buyFood(food);
    final boughtAgainWithoutEnoughPoints = await controller.buyFood(food);

    expect(bought, isTrue);
    expect(boughtAgainWithoutEnoughPoints, isFalse);
    expect(controller.points, 10);
    expect(controller.foodCount(food.name), 1);
  });

  test('consumes food by decrementing inventory', () async {
    final controller = await _controller(
      wallet: RewardWalletModel(
        points: 0,
        rewardedPomodoroIds: <String>[],
        rewardedTaskIds: <String>[],
        taskFocusSeconds: <String, int>{},
        foodInventory: <String, int>{'fish': 2},
      ),
    );
    const food = PetFood(
      species: 'cat',
      name: 'fish',
      cost: 20,
      hungerBoost: 12,
      moodBoost: 4,
    );

    final firstConsume = await controller.consumeFood(food);
    final secondConsume = await controller.consumeFood(food);
    final emptyConsume = await controller.consumeFood(food);

    expect(firstConsume, isTrue);
    expect(secondConsume, isTrue);
    expect(emptyConsume, isFalse);
    expect(controller.foodCount(food.name), 0);
    expect(
      controller.wallet.value!.foodInventory.containsKey(food.name),
      isFalse,
    );
  });
}

Future<RewardController> _controller({RewardWalletModel? wallet}) async {
  final repository = _repository();
  await repository.putWallet(wallet ?? RewardWalletModel.empty());
  final controller = RewardController(repository);
  controller.wallet.value = await repository.getWallet();
  return controller;
}

RewardRepository _repository() {
  return RewardRepository(
    box: Hive.box<RewardWalletModel>(BoxNames.rewardWallet),
  );
}

TaskModel _task({required String id}) {
  return TaskModel(id: id, title: 'Task', deadline: DateTime(2026, 5, 27));
}

PomodoroModel _pomodoro({
  required String id,
  String? taskId,
  required String type,
  required bool isCompleted,
  int actualSeconds = 25 * 60,
}) {
  return PomodoroModel(
    id: id,
    taskId: taskId,
    taskTitle: taskId == null ? null : 'Task',
    durationMinutes: type == 'focus' ? 25 : 5,
    actualSeconds: actualSeconds,
    startTime: DateTime(2026, 5, 27, 9),
    endTime: DateTime(2026, 5, 27, 9, 25),
    isCompleted: isCompleted,
    type: type,
  );
}

void _registerAdapter<T>(TypeAdapter<T> adapter) {
  if (!Hive.isAdapterRegistered(adapter.typeId)) {
    Hive.registerAdapter(adapter);
  }
}
