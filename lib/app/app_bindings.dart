import 'package:get/get.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/data/repositories/pet_repository.dart';
import 'package:todolist/data/repositories/pomodoro_repository.dart';
import 'package:todolist/data/repositories/reward_repository.dart';
import 'package:todolist/data/repositories/schedule_repository.dart';
import 'package:todolist/data/repositories/task_repository.dart';
import 'package:todolist/data/repositories/theme_settings_repository.dart';
import 'package:todolist/page/calendar/calendar_controller.dart';
import 'package:todolist/page/home/home_controller.dart';
import 'package:todolist/page/pet/pet_controller.dart';
import 'package:todolist/page/pet/reward_controller.dart';
import 'package:todolist/page/pomodoro/pomodoro_controller.dart';
import 'package:todolist/page/schedule/schedule_controller.dart';
import 'package:todolist/page/task/task_controller.dart';

void registerAppControllers() {
  _putDependency(() => ThemeSettingsRepository());
  _putDependency(() => TaskRepository());
  _putDependency(() => PetRepository());
  _putDependency(() => RewardRepository());
  _putDependency(() => PomodoroRepository());
  _putDependency(() => ScheduleRepository());

  _putController(() => ThemeController(Get.find<ThemeSettingsRepository>()));
  _putController(() => RewardController(Get.find<RewardRepository>()));
  _putController(() => PetController(Get.find<PetRepository>()));
  _putController(() => TaskController(Get.find<TaskRepository>()));
  _putController(() => PomodoroController(Get.find<PomodoroRepository>()));
  _putController(() => CalendarController());
  _putController(() => ScheduleController(Get.find<ScheduleRepository>()));
  _putController(() => HomeController());
}

void _putDependency<T>(T Function() builder) {
  if (!Get.isRegistered<T>()) {
    Get.put<T>(builder());
  }
}

void _putController<T>(T Function() builder) {
  if (!Get.isRegistered<T>()) {
    Get.put<T>(builder());
  }
}
