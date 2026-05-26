import 'package:todolist/app/app_bindings.dart';
import 'package:todolist/data/hive/hive_initializer.dart';

Future<void> initializeApp() async {
  await initializeHive();
  registerAppControllers();
}
