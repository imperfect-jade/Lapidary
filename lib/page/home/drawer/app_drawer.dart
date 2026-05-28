import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/page/home/home_controller.dart';

import '../dialogs/about_dialog.dart';
import '../dialogs/version_dialog.dart';
import '../guide/user_guide_page.dart';
import '../sheets/pet_settings_sheet.dart';
import '../sheets/settings_sheet.dart';

/// 首页侧边栏入口集合。
///
/// 抽屉只负责导航和弹出设置类面板，不持有业务状态；Tab 切换委托给 [HomeController]。
class HomeAppDrawer extends StatelessWidget {
  final HomeController homeController;

  const HomeAppDrawer({super.key, required this.homeController});

  @override
  Widget build(BuildContext context) {
    // 抽屉整体区域：顶部展示应用名，下方集中放置全局入口。
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              color: TaskTheme.appBarColor,
              child: const Text(
                '琢玉',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              // 回到宠物首页入口：只切换 Tab，不重新构建 HomePage。
              leading: const Icon(Icons.home_outlined),
              title: const Text('首页'),
              onTap: () {
                // “首页”入口约定回到宠物 Tab，保持应用的陪伴感首页定位。
                homeController.changeTab(2);
                Get.back();
              },
            ),
            ListTile(
              // 打开主题和字体设置 Sheet。
              leading: const Icon(Icons.settings_outlined),
              title: const Text('设置'),
              onTap: () {
                Get.back();
                showHomeSettingsSheet();
              },
            ),
            ListTile(
              // 打开宠物快捷设置 Sheet，提供改名和物种切换。
              leading: const Icon(Icons.pets),
              title: const Text('宠物'),
              onTap: () {
                Get.back();
                showHomePetSettingsSheet();
              },
            ),
            ListTile(
              // 使用指南是独立页面，展示应用主要工作流和宠物机制说明。
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('使用指南'),
              onTap: () {
                Get.back();
                Get.to(() => const UserGuidePage());
              },
            ),
            ListTile(
              // 关于弹窗只展示静态品牌介绍。
              leading: const Icon(Icons.auto_awesome_outlined),
              title: const Text('关于琢玉'),
              onTap: () {
                Get.back();
                showHomeAboutDialog();
              },
            ),
            ListTile(
              // 版本信息弹窗会异步读取平台包信息。
              leading: const Icon(Icons.info_outline),
              title: const Text('版本信息'),
              onTap: () {
                Get.back();
                showHomeVersionDialog();
              },
            ),
          ],
        ),
      ),
    );
  }
}
