part of '../home.dart';

class _AppDrawer extends StatelessWidget {
  final HomeController homeController;

  const _AppDrawer({required this.homeController});

  @override
  Widget build(BuildContext context) {
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
              leading: const Icon(Icons.home_outlined),
              title: const Text('首页'),
              onTap: () {
                homeController.changeTab(2);
                Get.back();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('设置'),
              onTap: () {
                Get.back();
                _showSettingsSheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.pets),
              title: const Text('宠物'),
              onTap: () {
                Get.back();
                _showPetSettingsSheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('使用指南'),
              onTap: () {
                Get.back();
                Get.to(() => const _UserGuidePage());
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome_outlined),
              title: const Text('关于琢玉'),
              onTap: () {
                Get.back();
                _showAboutDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('版本信息'),
              onTap: () {
                Get.back();
                _showVersionDialog();
              },
            ),
          ],
        ),
      ),
    );
  }
}
