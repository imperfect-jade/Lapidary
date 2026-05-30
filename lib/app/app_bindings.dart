import 'package:get/get.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/data/repositories/pet_diary_repository.dart';
import 'package:todolist/data/repositories/pet_repository.dart';
import 'package:todolist/data/repositories/pomodoro_repository.dart';
import 'package:todolist/data/repositories/reward_repository.dart';
import 'package:todolist/data/repositories/schedule_repository.dart';
import 'package:todolist/data/repositories/task_repository.dart';
import 'package:todolist/data/repositories/theme_settings_repository.dart';
import 'package:todolist/features/pet/services/pet_feedback_service.dart';
import 'package:todolist/features/pet/services/pet_message_service.dart';
import 'package:todolist/features/pet/services/pet_state_service.dart';
import 'package:todolist/features/productivity/services/productivity_feedback_service.dart';
import 'package:todolist/page/calendar/calendar_controller.dart';
import 'package:todolist/page/home/home_controller.dart';
import 'package:todolist/page/pet/pet_controller.dart';
import 'package:todolist/page/pet_diary/pet_diary_controller.dart';
import 'package:todolist/page/pet/reward_controller.dart';
import 'package:todolist/page/pomodoro/pomodoro_controller.dart';
import 'package:todolist/page/schedule/schedule_controller.dart';
import 'package:todolist/page/task/task_controller.dart';

void registerAppControllers() {
  _putDependency(() => ThemeSettingsRepository());
  _putDependency(() => TaskRepository());
  _putDependency(() => PetRepository());
  _putDependency(() => PetDiaryRepository());
  _putDependency(() => RewardRepository());
  _putDependency(() => PomodoroRepository());
  _putDependency(() => ScheduleRepository());
  _putDependency(() => PetStateService());
  _putDependency(() => PetMessageService());
  _putDependency(() => PetFeedbackService());

  _putController(() => ThemeController(Get.find<ThemeSettingsRepository>()));
  _putController(() => RewardController(Get.find<RewardRepository>()));
  _putController(
    () => PetController(
      Get.find<PetRepository>(),
      Get.find<PetStateService>(),
      Get.find<PetMessageService>(),
      Get.find<PetFeedbackService>(),
    ),
  );
  _putDependency(
    () => ProductivityFeedbackService(
      rewardPort: Get.find<RewardController>(),
      petPort: Get.find<PetController>(),
    ),
  );
  _putController(
    () => TaskController(
      Get.find<TaskRepository>(),
      Get.find<ProductivityFeedbackService>(),
    ),
  );
  _putController(
    () => PomodoroController(
      Get.find<PomodoroRepository>(),
      Get.find<ProductivityFeedbackService>(),
    ),
  );
  _putController(
    () => PetDiaryController(
      Get.find<PetDiaryRepository>(),
      Get.find<TaskRepository>(),
      Get.find<PomodoroRepository>(),
      Get.find<PetRepository>(),
    ),
  );
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
