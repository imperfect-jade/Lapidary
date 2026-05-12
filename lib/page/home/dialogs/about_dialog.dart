part of '../home.dart';

void _showAboutDialog() {
  Get.dialog(
    AlertDialog(
      title: const Text('关于琢玉'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('中文名：琢玉'),
          SizedBox(height: 8),
          Text('英文名：Lapidary'),
          SizedBox(height: 8),
          Text('作者：瓒'),
          SizedBox(height: 12),
          Text(
            '玉不琢，不成器；事不理，不成章。琢玉是一款融合待办、番茄钟、日历、四象限与像素宠物陪伴的效率应用，陪你把散落的念头打磨成清晰的计划，把平凡的一天雕琢出可见的进步。',
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('关闭')),
      ],
    ),
  );
}
