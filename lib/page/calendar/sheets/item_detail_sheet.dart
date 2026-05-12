part of '../calendar.dart';

// 事项详情
void _showItemDetail(
  CalendarModel item,
  CalendarController calenderController,
  TaskController taskController,
) {
  Get.bottomSheet(
    Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (item.description != null && item.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(item.description!, style: const TextStyle(color: Colors.grey)),
          ],
          const SizedBox(height: 12),
          // 如果是APP任务，提供同步到手机日历的选项
          if (item.source == 'app') ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.sync, color: Colors.blue),
              title: const Text('同步到手机日历'),
              subtitle: const Text('将该任务添加到手机系统日历'),
              onTap: () async {
                //同步任务到手机日历
                final task = taskController.taskList.firstWhere(
                  (t) => t.id == item.taskId,
                );
                final success = await calenderController.syncTaskToCalendar(
                  task,
                );
                Get.back();
                Get.snackbar(
                  success ? '同步成功' : '同步失败',
                  success ? '已添加到手机日历' : '请检查日历权限',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除任务'),
              onTap: () {
                final task = taskController.taskList.firstWhere(
                  (t) => t.id == item.taskId,
                );
                taskController.deleteTask(task);
                Get.back();
              },
            ),
          ],
          // 如果是手机日历事件
          if (item.source == 'device') ...[
            const Divider(),
            const Text(
              '来自手机日历',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            if (item.startTime != null)
              Text('时间：${_formatDateTime(item.startTime!)}'),
          ],
        ],
      ),
    ),
  );
}
