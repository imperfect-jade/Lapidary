import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/page/calendar/calendar.dart';
import 'package:todolist/page/home/drawer/app_drawer.dart';
import 'package:todolist/page/home/home_controller.dart';
import 'package:todolist/page/pet/pet.dart';
import 'package:todolist/page/pet/widgets/pet_global_feedback_overlay.dart';
import 'package:todolist/page/pomodoro/pomodoro.dart';
import 'package:todolist/page/quadrant/quadrant.dart';
import 'package:todolist/page/task/task.dart';

/// 首页根页面，负责承载底部五个功能 Tab、侧边栏和全局宠物反馈浮层。
///
/// 这里不直接处理各功能页的业务逻辑，只组合页面入口并维护当前选中的 Tab。
class HomePage extends StatelessWidget {
  HomePage({super.key});

  /// 首页控制器由应用启动绑定统一注册，这里只通过 GetX 获取全局实例。
  final HomeController controller = Get.find<HomeController>();
  late final List<Widget> _children = _getChildren();
  late final List<BottomNavigationBarItem> _tabBarItems = _getTabBarWidget();

  /// 构建底部导航对应的五个主功能页面。
  ///
  /// 页面顺序必须和 [HomeController.tabList] 保持一致，否则底部导航索引会指向错误页面。
  List<Widget> _getChildren() {
    return [
      TaskPage(),
      PomodoroPage(),
      PetPage(),
      QuadrantPage(),
      CalendarPage(),
    ];
  }

  /// 根据控制器中的 Tab 元数据生成底部导航项。
  ///
  /// 每一项包含未选中图标、选中图标和标题；这些元数据由 [HomeController.tabList] 统一维护。
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
    // 首页整体骨架：侧边栏、主内容叠层和底部导航都在这一层组合。
    return Scaffold(
      // 左侧抽屉承载设置、宠物设置、指南、关于和版本等全局入口。
      drawer: HomeAppDrawer(homeController: controller),
      // 主内容区包在 SafeArea 内，避免顶部状态栏和底部系统手势区域遮挡页面。
      body: SafeArea(
        child: Builder(
          builder: (context) {
            // Stack 用来叠放当前功能页、左上角菜单按钮和非宠物页的全局宠物浮层。
            return Stack(
              children: [
                Obx(() {
                  TaskTheme.palette;
                  // 主页面区域：由 currentIndex 驱动显示当前 Tab。
                  // 使用 IndexedStack 保留各功能页状态，切换 Tab 时不重新创建页面。
                  return IndexedStack(
                    index: controller.currentIndex.value,
                    children: _children,
                  );
                }),
                Positioned(
                  top: 10,
                  left: 10,
                  // 左上角菜单按钮：覆盖在各 Tab 页面之上，用当前 Scaffold 上下文打开抽屉。
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
                Obx(() {
                  if (controller.currentIndex.value == 2) {
                    // 全局宠物反馈浮层：由宠物反馈服务驱动，在任务/番茄钟等页面提供轻量反馈。
                    // 宠物页已有主舞台，隐藏全局浮层以避免重复显示。
                    return const SizedBox.shrink();
                  }
                  return const PetGlobalFeedbackOverlay();
                }),
              ],
            );
          },
        ),
      ),
      // 底部导航区：显示五个功能入口，点击后通过 HomeController.changeTab 更新 currentIndex。
      // 这里读取 TaskTheme.palette，让主题切换后导航颜色可以响应式刷新。
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
