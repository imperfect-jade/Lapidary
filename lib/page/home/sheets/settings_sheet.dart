import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/page/home/settings/font_settings_section.dart';
import 'package:todolist/page/home/settings/theme_settings_section.dart';

void showHomeSettingsSheet() {
  Get.bottomSheet(
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
