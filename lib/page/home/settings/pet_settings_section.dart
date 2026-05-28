import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/model/pet/pet.dart';
import 'package:todolist/page/pet/pet_controller.dart';

import 'pet_name_dialog.dart';

/// 首页侧边栏中的宠物快捷设置区。
///
/// 只暴露改名和猫狗切换这类轻量操作，避免在首页设置中承载完整养成逻辑。
class HomePetSettingsSection extends StatelessWidget {
  const HomePetSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final petController = Get.find<PetController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 区块标题：提示用户当前区域用于管理首页侧边栏里的宠物快捷项。
        const Text(
          '宠物设置',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Obx(() {
          // 宠物数据可能在初始化早期为空，空值时使用默认猫作为展示兜底。
          final pet = petController.pet.value;
          final species = pet?.species ?? PetSpecies.cat;
          return Column(
            children: [
              // 宠物名称行：展示当前名称，点击修改时打开改名弹窗。
              _PetNameEditor(
                name: pet?.name ?? '小云',
                onEdit: () => showPetNameDialog(petController, pet?.name),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // 猫/狗物种卡片：显示当前选择状态，点击后委托 PetController 保存物种。
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
                      icon: Icons.pets,
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
