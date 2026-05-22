part of '../home.dart';

void _showSettingsSheet() {
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
            _ThemeSettingsSection(),
            SizedBox(height: 18),
            _FontSettingsSection(),
            SizedBox(height: 8),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
  );
}
