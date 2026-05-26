import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:todolist/data/hive/box_names.dart';
import 'package:todolist/data/repositories/pet_repository.dart';
import 'package:todolist/data/repositories/reward_repository.dart';
import 'package:todolist/data/repositories/task_repository.dart';
import 'package:todolist/model/pet/pet.dart';
import 'package:todolist/model/reward/reward_wallet.dart';
import 'package:todolist/model/task/task.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'todolist_repository_test_',
    );
    Hive.init(tempDir.path);
    _registerAdapter(TaskModelAdapter());
    _registerAdapter(PetModelAdapter());
    _registerAdapter(RewardWalletModelAdapter());
    await Hive.openBox<TaskModel>(BoxNames.tasks);
    await Hive.openBox<PetModel>(BoxNames.pets);
    await Hive.openBox<RewardWalletModel>(BoxNames.rewardWallet);
  });

  tearDown(() async {
    await Hive.box<TaskModel>(BoxNames.tasks).clear();
    await Hive.box<PetModel>(BoxNames.pets).clear();
    await Hive.box<RewardWalletModel>(BoxNames.rewardWallet).clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('TaskRepository reads, saves, and deletes tasks', () async {
    final repository = TaskRepository();
    final task = TaskModel(
      id: 'task-1',
      title: '测试任务',
      deadline: DateTime(2026, 5, 26, 10),
    );

    await repository.put(task);
    expect(repository.getAll(), hasLength(1));

    task.title = '更新后的任务';
    await repository.save(task);
    expect(repository.getAll().single.title, '更新后的任务');

    await repository.delete(task);
    expect(repository.getAll(), isEmpty);
  });

  test('PetRepository creates the default pet when missing', () async {
    final repository = PetRepository();

    final pet = await repository.getDefaultPet();

    expect(pet.id, PetRepository.defaultPetKey);
    expect(pet.species, PetSpecies.cat);
    expect(Hive.box<PetModel>(BoxNames.pets).containsKey(pet.id), isTrue);
  });

  test('RewardRepository creates and saves the default wallet', () async {
    final repository = RewardRepository();

    final wallet = await repository.getWallet();
    expect(wallet.points, 0);
    expect(
      Hive.box<RewardWalletModel>(
        BoxNames.rewardWallet,
      ).containsKey(RewardRepository.walletKey),
      isTrue,
    );

    wallet.points = 42;
    await repository.save(wallet);
    expect((await repository.getWallet()).points, 42);
  });
}

void _registerAdapter<T>(TypeAdapter<T> adapter) {
  if (!Hive.isAdapterRegistered(adapter.typeId)) {
    Hive.registerAdapter(adapter);
  }
}
