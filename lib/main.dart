import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/model/pet/pet.dart';
import 'package:todolist/model/pomodoro/pomodoro.dart';
import 'package:todolist/model/reward/reward_wallet.dart';
import 'package:todolist/model/task/task.dart';
import 'package:todolist/page/calendar/calendar_controller.dart';
import 'package:todolist/page/pet/pet_controller.dart';
import 'package:todolist/page/pet/reward_controller.dart';
import 'package:todolist/page/pomodoro/pomodoro_controller.dart';
import 'package:todolist/page/task/task_controller.dart';
import 'package:todolist/routes/index.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  //初始化Hive数据库
  await Hive.initFlutter();
  //注册数据模型
  Hive.registerAdapter(TaskModelAdapter());
  Hive.registerAdapter(PomodoroModelAdapter());
  Hive.registerAdapter(PetModelAdapter());
  Hive.registerAdapter(RewardWalletModelAdapter());
  //打开数据库
  await Hive.openBox<TaskModel>('tasks');
  await Hive.openBox<PomodoroModel>('pomodoros');
  await Hive.openBox<PetModel>('pets');
  await Hive.openBox<RewardWalletModel>('reward_wallet');
  await Hive.openBox(ThemeController.settingsBoxName);
  // 注册Controller
  Get.put(ThemeController());
  Get.put(RewardController());
  Get.put(TaskController());
  Get.put(PomodoroController());
  Get.put(CalendarController());
  Get.put(PetController());

  //运行应用
  runApp(getRouteWidget());
}
