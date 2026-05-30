import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:todolist/data/hive/box_names.dart';
import 'package:todolist/data/repositories/pet_diary_repository.dart';
import 'package:todolist/data/repositories/pet_repository.dart';
import 'package:todolist/data/repositories/pomodoro_repository.dart';
import 'package:todolist/data/repositories/task_repository.dart';
import 'package:todolist/model/pet/pet.dart';
import 'package:todolist/model/pet_diary/pet_diary.dart';
import 'package:todolist/model/pomodoro/pomodoro.dart';
import 'package:todolist/model/task/task.dart';
import 'package:todolist/page/pet_diary/pet_diary_controller.dart';

void main() {
  late Directory tempDir;
  late Box<TaskModel> taskBox;
  late Box<PomodoroModel> pomodoroBox;
  late Box<PetModel> petBox;
  late Box<PetDiaryModel> diaryBox;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'todolist_pet_diary_controller_test_',
    );
    Hive.init(tempDir.path);
    _registerAdapter(TaskModelAdapter());
    _registerAdapter(PomodoroModelAdapter());
    _registerAdapter(PetModelAdapter());
    _registerAdapter(PetDiaryModelAdapter());
    taskBox = await Hive.openBox<TaskModel>(BoxNames.tasks);
    pomodoroBox = await Hive.openBox<PomodoroModel>(BoxNames.pomodoros);
    petBox = await Hive.openBox<PetModel>(BoxNames.pets);
    diaryBox = await Hive.openBox<PetDiaryModel>(BoxNames.petDiaries);
  });

  tearDown(() async {
    await taskBox.clear();
    await pomodoroBox.clear();
    await petBox.clear();
    await diaryBox.clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('uses a matching positive response for two completed tasks', () async {
    final controller = _controller(
      taskBox: taskBox,
      pomodoroBox: pomodoroBox,
      petBox: petBox,
      diaryBox: diaryBox,
    );
    final now = DateTime.now();
    await taskBox.put('task-1', _completedTask('task-1', now));
    await taskBox.put('task-2', _completedTask('task-2', now));

    final diary = await controller.regenerateTodayDiary();

    expect(diary, isNotNull);
    expect(diary!.completedTaskCount, 2);
    expect(diary.diaryText, contains('今天你完成了 2 个任务'));
    expect(diary.diaryText, contains('稳稳推进'));
    expect(diary.diaryText, isNot(contains('没关系，我们明天先从一个很小的任务开始')));
  });

  test(
    'hides stale today diary when regenerated with no source data',
    () async {
      final controller = _controller(
        taskBox: taskBox,
        pomodoroBox: pomodoroBox,
        petBox: petBox,
        diaryBox: diaryBox,
      );
      final now = DateTime.now();
      final diaryId = _dateId(now);
      await diaryBox.put(
        diaryId,
        PetDiaryModel(
          id: diaryId,
          date: DateTime(now.year, now.month, now.day),
          completedTaskCount: 2,
          focusMinutes: 0,
          focusSessionCount: 0,
          lateNightTaskCount: 0,
          diaryText: '今天你完成了 2 个任务\n旧日记',
          generatedAt: now,
        ),
      );

      controller.loadDiaries();
      expect(controller.todayDiary.value, isNull);
      expect(controller.diaries, isEmpty);
      expect(await controller.ensureTodayDiary(), isNull);

      final diary = await controller.regenerateTodayDiary();

      expect(diary, isNull);
      expect(controller.todayDiary.value, isNull);
      expect(controller.diaries, isEmpty);
    },
  );
}

PetDiaryController _controller({
  required Box<TaskModel> taskBox,
  required Box<PomodoroModel> pomodoroBox,
  required Box<PetModel> petBox,
  required Box<PetDiaryModel> diaryBox,
}) {
  return PetDiaryController(
    PetDiaryRepository(box: diaryBox),
    TaskRepository(box: taskBox),
    PomodoroRepository(box: pomodoroBox),
    PetRepository(box: petBox),
  );
}

TaskModel _completedTask(String id, DateTime completedAt) {
  return TaskModel(
    id: id,
    title: 'Task $id',
    deadline: completedAt.add(const Duration(days: 1)),
    isCompleted: true,
    completedAt: completedAt,
  );
}

String _dateId(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  return '${day.year}-${_two(day.month)}-${_two(day.day)}';
}

String _two(int value) {
  return value.toString().padLeft(2, '0');
}

void _registerAdapter<T>(TypeAdapter<T> adapter) {
  if (!Hive.isAdapterRegistered(adapter.typeId)) {
    Hive.registerAdapter(adapter);
  }
}
