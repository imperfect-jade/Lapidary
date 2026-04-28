import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:todolist/page/home/home.dart';
//返回app根级组件
Widget getRouteWidget() {
  return GetMaterialApp(
    //命名路由
    initialRoute: "/",
    routes: getRootRoutes(),
  );
}

//返回该APP的路由配置
Map<String, Widget Function(BuildContext)> getRootRoutes(){
  return {
    "/": (context) => HomePage(), //主页路由
  };
}