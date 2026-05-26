import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/page/home/home.dart';

Widget getRouteWidget() {
  final themeController = Get.find<ThemeController>();
  return Obx(() {
    final palette = themeController.currentPalette;
    final bodyFontFamily = themeController.currentBodyFontFamily;
    return GetMaterialApp(
      theme: ThemeData(
        fontFamily: bodyFontFamily,
        scaffoldBackgroundColor: palette.primaryColor,
        primaryColor: palette.appBarColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: palette.selectedColor,
          primary: palette.selectedColor,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: palette.appBarColor,
          foregroundColor: Colors.black,
          centerTitle: true,
          systemOverlayStyle: themeController.systemUiOverlayStyle,
        ),
      ),
      initialRoute: '/',
      routes: getRootRoutes(),
    );
  });
}

Map<String, Widget Function(BuildContext)> getRootRoutes() {
  return {'/': (context) => HomePage()};
}
