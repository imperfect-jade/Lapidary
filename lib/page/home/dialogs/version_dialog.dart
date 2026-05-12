part of '../home.dart';

void _showVersionDialog() {
  Get.dialog(
    AlertDialog(
      title: const Text('版本信息'),
      content: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final version = _formatPackageVersion(snapshot.data);

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('应用名称：待办陪伴'),
              const SizedBox(height: 8),
              Text('当前版本：$version'),
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

String _formatPackageVersion(PackageInfo? info) {
  if (info == null) {
    return '加载中...';
  }
  if (info.buildNumber.isEmpty) {
    return info.version;
  }
  return '${info.version}+${info.buildNumber}';
}
