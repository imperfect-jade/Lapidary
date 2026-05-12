part of '../home.dart';

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
          Text('当前版本：1.0.1+1'),  // 当前版本号
        ],
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('关闭')),
      ],
    ),
  );
}
