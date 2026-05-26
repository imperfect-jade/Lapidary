import 'package:flutter/material.dart';
import 'package:todolist/app/app_bootstrap.dart';

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppBootstrap());
}
