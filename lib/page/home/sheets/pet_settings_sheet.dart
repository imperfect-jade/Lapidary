import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/page/home/settings/pet_settings_section.dart';

/// 打开宠物设置底部 Sheet。
///
/// 这里只承载首页侧边栏中的宠物快捷设置，完整互动仍保留在宠物页。
void showHomePetSettingsSheet() {
  Get.bottomSheet(
    // 宠物快捷设置 Sheet 内容区：标题 + 宠物设置表单。
    // 宠物状态来自 PetController，改名和物种切换会直接调用宠物模块公开 API。
    Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '宠物',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 18),
            HomePetSettingsSection(),
            SizedBox(height: 8),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
  );
}
