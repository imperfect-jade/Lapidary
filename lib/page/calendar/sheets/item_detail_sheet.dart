import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/model/calendar/calendar.dart';
import 'package:todolist/page/calendar/calendar_controller.dart';
import 'package:todolist/page/calendar/utils/formatters.dart';
import 'package:todolist/page/task/task_controller.dart';

// 事项详情
void showCalendarItemDetail(
  CalendarModel item,
  CalendarController calenderController,
  TaskController taskController,
) {
  final linkedTask = item.source == 'app'
      ? taskController.findTaskById(item.taskId)
      : null;
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
            if (linkedTask == null)
              const ListTile(
                leading: Icon(Icons.warning_amber, color: Colors.orange),
                title: Text('任务已不存在'),
                subtitle: Text('该日历事项关联的本地任务可能已被删除'),
              )
            else ...[
              ListTile(
                leading: const Icon(Icons.sync, color: Colors.blue),
                title: const Text('同步到手机日历'),
                subtitle: const Text('将该任务添加到手机系统日历'),
                onTap: () async {
                  //同步任务到手机日历
                  final success = await calenderController.syncTaskToCalendar(
                    linkedTask,
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
                  taskController.deleteTask(linkedTask);
                  Get.back();
                },
              ),
            ],
          ],
          // 如果是手机日历事件
          if (item.source == 'device') ...[
            const Divider(),
            const Text(
              '来自手机日历',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            if (item.startTime != null)
              Text('时间：${formatCalendarDateTime(item.startTime!)}'),
          ],
        ],
      ),
    ),
  );
}
