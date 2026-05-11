import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/page/home/home.dart';

//返回app根级组件
Widget getRouteWidget() {
  final themeController = Get.find<ThemeController>();
  return Obx(() {
    final palette = themeController.currentPalette;
    return GetMaterialApp(
      theme: ThemeData(
        fontFamily: 'HarmonyOSSansSC',
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
      //命名路由
      initialRoute: "/",
      routes: getRootRoutes(),
    );
  });
}

//返回该APP的路由配置
Map<String, Widget Function(BuildContext)> getRootRoutes() {
  return {
    "/": (context) => HomePage(), //主页路由
  };
}
