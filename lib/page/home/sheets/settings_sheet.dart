import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/page/home/settings/font_settings_section.dart';
import 'package:todolist/page/home/settings/theme_settings_section.dart';

/// 打开首页设置底部 Sheet。
///
/// Sheet 只组合主题和字体设置区，具体持久化交给 ThemeController 与其 Repository。
void showHomeSettingsSheet() {
  Get.bottomSheet(
    // 设置 Sheet 内容区：标题 + 主题设置 + 字体设置。
    // 具体选项状态来自 ThemeController，Sheet 本身不保存任何设置值。
    Container(
      width: double.infinity,
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
            HomeThemeSettingsSection(),
            SizedBox(height: 18),
            HomeFontSettingsSection(),
            SizedBox(height: 8),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
  );
}
