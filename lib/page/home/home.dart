import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/model/pet/pet.dart';
import 'package:todolist/page/calendar/calendar.dart';
import 'package:todolist/page/pet/pet.dart';
import 'package:todolist/page/pet/pet_controller.dart';
import 'package:todolist/page/pomodoro/pomodoro.dart';
import 'package:todolist/page/quadrant/quadrant.dart';
import 'package:todolist/page/task/task.dart';
import 'package:todolist/page/home/home_controller.dart';

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
                  top: 8,
                  left: 8,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(8),
                    child: IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      tooltip: '侧边栏',
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
                '待办陪伴',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('首页'),
              onTap: () {
                homeController.changeTab(0);
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

void _showVersionDialog() {
  Get.dialog(
    AlertDialog(
      title: const Text('版本信息'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('应用名称：待办陪伴'),
          SizedBox(height: 8),
          Text('当前版本：1.0.0+1'),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('关闭')),
      ],
    ),
  );
}

void _showSettingsSheet() {
  Get.bottomSheet(
    Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              '设置',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 18),
            _ThemeSettingsSection(),
            SizedBox(height: 22),
            _PetSettingsSection(),
            SizedBox(height: 8),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
  );
}

class _ThemeSettingsSection extends StatelessWidget {
  const _ThemeSettingsSection();

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '主题色设置',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Obx(
          () => Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ThemeController.palettes.map((palette) {
              final selected =
                  themeController.currentThemeKey.value == palette.key;
              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => themeController.changeTheme(palette.key),
                child: Container(
                  width: 138,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: palette.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? palette.selectedColor : Colors.white,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _ColorDot(color: palette.appBarColor),
                          const SizedBox(width: 5),
                          _ColorDot(color: palette.primaryColor),
                          const SizedBox(width: 5),
                          _ColorDot(color: palette.selectedColor),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        palette.label,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (selected) ...[
                        const SizedBox(height: 6),
                        const Text(
                          '当前使用',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;

  const _ColorDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}

class _PetSettingsSection extends StatelessWidget {
  const _PetSettingsSection();

  @override
  Widget build(BuildContext context) {
    final petController = Get.find<PetController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '宠物设置',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Obx(() {
          final pet = petController.pet.value;
          final species = pet?.species ?? PetSpecies.cat;
          return Column(
            children: [
              _PetNameEditor(
                name: pet?.name ?? '小云',
                onEdit: () => _showPetNameDialog(petController, pet?.name),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _PetOptionCard(
                      title: '像素小猫',
                      subtitle: species == PetSpecies.cat ? '当前伙伴' : '可选择',
                      icon: Icons.pets,
                      selected: species == PetSpecies.cat,
                      enabled: true,
                      onTap: () =>
                          petController.selectPetSpecies(PetSpecies.cat),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PetOptionCard(
                      title: '像素小狗',
                      subtitle: species == PetSpecies.dog ? '当前伙伴' : '可选择',
                      icon: Icons.cruelty_free,
                      selected: species == PetSpecies.dog,
                      enabled: true,
                      onTap: () =>
                          petController.selectPetSpecies(PetSpecies.dog),
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
      ],
    );
  }
}

class _PetNameEditor extends StatelessWidget {
  final String name;
  final VoidCallback onEdit;

  const _PetNameEditor({required this.name, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: TaskTheme.primaryColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        children: [
          const Icon(Icons.badge_outlined, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '宠物名字：$name',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('修改'),
          ),
        ],
      ),
    );
  }
}

void _showPetNameDialog(PetController petController, String? currentName) {
  final nameController = TextEditingController(text: currentName ?? '');
  Get.dialog(
    AlertDialog(
      title: const Text('修改宠物名字'),
      content: TextField(
        controller: nameController,
        autofocus: true,
        maxLength: 8,
        decoration: const InputDecoration(
          labelText: '宠物名字',
          hintText: '最多 8 个字符',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('取消')),
        ElevatedButton(
          onPressed: () async {
            final name = nameController.text.trim();
            if (name.isEmpty) {
              Get.snackbar(
                '名字不能为空',
                '给宠物取一个简短的名字吧',
                snackPosition: SnackPosition.BOTTOM,
              );
              return;
            }
            if (name.length > 8) {
              Get.snackbar(
                '名字太长',
                '宠物名字最多 8 个字符',
                snackPosition: SnackPosition.BOTTOM,
              );
              return;
            }
            final success = await petController.renamePet(name);
            if (!success) {
              Get.snackbar(
                '修改失败',
                '请检查名字后再试',
                snackPosition: SnackPosition.BOTTOM,
              );
              return;
            }
            Get.back();
          },
          child: const Text('保存'),
        ),
      ],
    ),
  ).whenComplete(nameController.dispose);
}

class _PetOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  const _PetOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: TaskTheme.primaryColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? TaskTheme.selectedColor : Colors.white,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 30, color: TaskTheme.selectedColor),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
