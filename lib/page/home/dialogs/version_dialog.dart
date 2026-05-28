import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 显示版本信息弹窗。
///
/// 版本号来自平台包信息，避免在 UI 中手写版本导致和 pubspec 不一致。
void showHomeVersionDialog() {
  Get.dialog(
    // 版本弹窗 UI：展示应用名、版本号和仓库地址。
    // 版本号异步读取，避免阻塞弹窗打开。
    AlertDialog(
      title: const Text('版本信息'),
      content: FutureBuilder<PackageInfo>(
        // PackageInfo 读取依赖平台通道，因此用 FutureBuilder 展示异步结果。
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final version = _formatPackageVersion(snapshot.data);

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('应用名称：琢玉（Lapidary）'),
              const SizedBox(height: 8),
              Text('当前版本：$version'),
              const SizedBox(height: 8),
              const Text('GitHub 仓库：'),
              const SizedBox(height: 4),
              const SelectableText(
                'https://github.com/imperfect-jade/Lapidary.git',
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('关闭')),
      ],
    ),
  );
}

/// 将平台读取到的版本号和构建号合并为统一展示文本。
String _formatPackageVersion(PackageInfo? info) {
  if (info == null) {
    return '加载中...';
  }
  if (info.buildNumber.isEmpty) {
    return info.version;
  }
  return '${info.version}+${info.buildNumber}';
}
