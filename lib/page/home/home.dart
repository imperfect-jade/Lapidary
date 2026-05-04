import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/page/calendar/calendar.dart';
import 'package:todolist/page/pet/pet.dart';
import 'package:todolist/page/pomodoro/pomodoro.dart';
import 'package:todolist/page/quadrant/quadrant.dart';
import 'package:todolist/page/task/task.dart';
import 'package:todolist/page/home/home_controller.dart';

//主页
class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);
  //获取控制器
  final HomeController controller = Get.put(HomeController());
  late final List<Widget> _children = _getChildren();
  late final List<BottomNavigationBarItem> _tabBarItems = _getTabBarWidget();

  List<Widget> _getChildren() {
    return [
      TaskPage(),
      PomodoroPage(),
      QuadrantPage(),
      CalendarPage(),
      PetPage(),
    ];
  }

  //获取tab栏项
  List<BottomNavigationBarItem> _getTabBarWidget() {
    return List.generate(controller.tabList.length, (int index) {
      return BottomNavigationBarItem(
        icon: Image.asset(
          controller.tabList[index]["icon"]!,
          width: 30,
          height: 30,
        ),
        activeIcon: Image.asset(
          controller.tabList[index]["active_icon"]!,
          width: 30,
          height: 30,
        ),
        label: controller.tabList[index]["title"]!,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Obx(
          () => IndexedStack(
            index: controller.currentIndex.value,
            children: _children,
          ),
        ),
      ),
      //底部导航栏
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          showUnselectedLabels: true,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          onTap: controller.changeTab,
          items: _tabBarItems,
          currentIndex: controller.currentIndex.value,
        ),
      ),
    );
  }
}
