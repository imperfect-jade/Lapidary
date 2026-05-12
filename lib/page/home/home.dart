import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/model/pet/pet.dart';
import 'package:todolist/page/calendar/calendar.dart';
import 'package:todolist/page/pet/pet.dart';
import 'package:todolist/page/pet/pet_controller.dart';
import 'package:todolist/page/pomodoro/pomodoro.dart';
import 'package:todolist/page/quadrant/quadrant.dart';
import 'package:todolist/page/task/task.dart';
import 'package:todolist/page/home/home_controller.dart';

part 'dialogs/version_dialog.dart';
part 'dialogs/about_dialog.dart';
part 'drawer/app_drawer.dart';
part 'settings/pet_name_dialog.dart';
part 'settings/pet_settings_section.dart';
part 'settings/font_settings_section.dart';
part 'settings/theme_settings_section.dart';
part 'sheets/pet_settings_sheet.dart';
part 'sheets/settings_sheet.dart';

//主页
class HomePage extends StatelessWidget {
  HomePage({super.key});
  //获取控制器
  final HomeController controller = Get.put(HomeController());
  late final List<Widget> _children = _getChildren();
  late final List<BottomNavigationBarItem> _tabBarItems = _getTabBarWidget();

  List<Widget> _getChildren() {
    return [
      TaskPage(),
      PomodoroPage(),
      PetPage(),
      QuadrantPage(),
      CalendarPage(),
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
      drawer: _AppDrawer(homeController: controller),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            return Stack(
              children: [
                Obx(() {
                  TaskTheme.palette;
                  return IndexedStack(
                    index: controller.currentIndex.value,
                    children: _children,
                  );
                }),
                Positioned(
                  top: 10,
                  left: 10,
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(8),
                      child: IconButton(
                        icon: const Icon(Icons.menu),
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 36,
                          height: 36,
                        ),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        tooltip: '侧边栏',
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      //底部导航栏
      bottomNavigationBar: Obx(() {
        TaskTheme.palette;
        return BottomNavigationBar(
          showUnselectedLabels: true,
          selectedItemColor: TaskTheme.selectedColor,
          unselectedItemColor: Colors.grey,
          onTap: controller.changeTab,
          items: _tabBarItems,
          currentIndex: controller.currentIndex.value,
        );
      }),
    );
  }
}
