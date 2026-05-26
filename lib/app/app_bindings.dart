import 'package:get/get.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/page/calendar/calendar_controller.dart';
import 'package:todolist/page/home/home_controller.dart';
import 'package:todolist/page/pet/pet_controller.dart';
import 'package:todolist/page/pet/reward_controller.dart';
import 'package:todolist/page/pomodoro/pomodoro_controller.dart';
import 'package:todolist/page/schedule/schedule_controller.dart';
import 'package:todolist/page/task/task_controller.dart';

void registerAppControllers() {
  _putController(() => ThemeController());
  _putController(() => RewardController());
  _putController(() => PetController());
  _putController(() => TaskController());
  _putController(() => PomodoroController());
  _putController(() => CalendarController());
  _putController(() => ScheduleController());
  _putController(() => HomeController());
}

void _putController<T>(T Function() builder) {
  if (!Get.isRegistered<T>()) {
    Get.put<T>(builder());
  }
}
