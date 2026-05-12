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
import 'package:todolist/page/splash/splash.dart';
import 'package:todolist/page/task/task_controller.dart';
import 'package:todolist/routes/index.dart';

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppBootstrap());
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  bool _initialized = false;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Future.wait([
        initializeApp(),
        Future<void>.delayed(const Duration(milliseconds: 1200)),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _initialized = true;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initialized) {
      return getRouteWidget();
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: ThemeController.defaultBodyFontFamily),
      home: SplashPage(
        isLoading: _loading,
        errorMessage: _error?.toString(),
        onRetry: _initialize,
      ),
    );
  }
}

Future<void> initializeApp() async {
  await Hive.initFlutter();
  _registerAdapter(TaskModelAdapter());
  _registerAdapter(PomodoroModelAdapter());
  _registerAdapter(PetModelAdapter());
  _registerAdapter(RewardWalletModelAdapter());

  await _openTypedBox<TaskModel>('tasks');
  await _openTypedBox<PomodoroModel>('pomodoros');
  await _openTypedBox<PetModel>('pets');
  await _openTypedBox<RewardWalletModel>('reward_wallet');
  await _openBox(ThemeController.settingsBoxName);

  _putController(() => ThemeController());
  _putController(() => RewardController());
  _putController(() => TaskController());
  _putController(() => PomodoroController());
  _putController(() => CalendarController());
  _putController(() => PetController());
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

void _putController<T>(T Function() builder) {
  if (!Get.isRegistered<T>()) {
    Get.put<T>(builder());
  }
}
