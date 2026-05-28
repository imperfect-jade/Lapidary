import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/model/calendar/calendar.dart';
import 'package:todolist/page/calendar/calendar_controller.dart';
import 'package:todolist/page/calendar/utils/formatters.dart';
import 'package:todolist/page/task/task_controller.dart';

/// 月历事项详情 Sheet。
///
/// APP 任务会提供同步到手机日历和删除任务入口；手机日历事件只展示来源和时间。
/// 这里不直接改写任务字段，删除和同步都委托对应 Controller。
void showCalendarItemDetail(
  CalendarModel item,
  CalendarController calenderController,
  TaskController taskController,
) {
  // APP 事项需要回查本地任务，防止任务被删除后详情仍显示可操作入口。
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
          // APP 任务区：提供同步到手机日历和删除本地任务两个操作。
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
                  // 同步任务到手机日历，只写设备日历，不修改本地任务模型。
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
                  // 删除仍走 TaskController，保持任务列表、四象限和月历缓存同步。
                  taskController.deleteTask(linkedTask);
                  Get.back();
                },
              ),
            ],
          ],
          // 手机日历事件区：只读展示，不提供编辑设备日历事件入口。
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
