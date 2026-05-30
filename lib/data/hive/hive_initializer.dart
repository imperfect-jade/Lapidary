import 'package:hive_flutter/hive_flutter.dart';
import 'package:todolist/data/hive/box_names.dart';
import 'package:todolist/model/pet/pet.dart';
import 'package:todolist/model/pet_diary/pet_diary.dart';
import 'package:todolist/model/pomodoro/pomodoro.dart';
import 'package:todolist/model/reward/reward_wallet.dart';
import 'package:todolist/model/schedule/schedule.dart';
import 'package:todolist/model/task/task.dart';

Future<void> initializeHive() async {
  await Hive.initFlutter();
  _registerAdapter(TaskModelAdapter());
  _registerAdapter(PomodoroModelAdapter());
  _registerAdapter(PetModelAdapter());
  _registerAdapter(PetDiaryModelAdapter());
  _registerAdapter(RewardWalletModelAdapter());
  _registerAdapter(ScheduleSessionModelAdapter());
  _registerAdapter(ScheduleSemesterModelAdapter());

  await _openTypedBox<TaskModel>(BoxNames.tasks);
  await _openTypedBox<PomodoroModel>(BoxNames.pomodoros);
  await _openTypedBox<PetModel>(BoxNames.pets);
  await _openTypedBox<PetDiaryModel>(BoxNames.petDiaries);
  await _openTypedBox<RewardWalletModel>(BoxNames.rewardWallet);
  await _openTypedBox<ScheduleSemesterModel>(BoxNames.scheduleSemesters);
  await _openBox(BoxNames.settings);
}

void _registerAdapter<T>(TypeAdapter<T> adapter) {
  if (!Hive.isAdapterRegistered(adapter.typeId)) {
    Hive.registerAdapter(adapter);
  }
}

Future<Box<T>> _openTypedBox<T>(String name) async {
  if (Hive.isBoxOpen(name)) {
    return Hive.box<T>(name);
  }
  return Hive.openBox<T>(name);
}

Future<Box> _openBox(String name) async {
  if (Hive.isBoxOpen(name)) {
    return Hive.box(name);
  }
  return Hive.openBox(name);
}
