import 'package:flutter/material.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/features/schedule/services/schedule_color_service.dart';
import 'package:todolist/model/calendar/calendar.dart';
import 'package:todolist/model/schedule/schedule.dart';
import 'package:todolist/page/calendar/calendar_controller.dart';
import 'package:todolist/page/calendar/sheets/item_detail_sheet.dart';
import 'package:todolist/page/calendar/sheets/schedule_session_sheet.dart';
import 'package:todolist/page/calendar/utils/formatters.dart';
import 'package:todolist/page/calendar/utils/schedule_calendar_helpers.dart';
import 'package:todolist/page/schedule/schedule_controller.dart';
import 'package:todolist/page/task/task_controller.dart';

/// 月历事项卡片，用于展示 APP 任务或手机系统日历事件。
///
/// APP 任务的完成勾选仍调用 `TaskController.updateTaskStatus()`；
/// 设备日历事件只读展示，不在卡片中修改系统日历。
Widget buildCalendarItemCard(
  CalendarModel item,
  CalendarController calenderController,
  TaskController taskController,
) {
  // source 决定卡片颜色、来源标签和是否显示完成 Checkbox。
  final isApp = item.source == 'app';
  final linkedTask = isApp ? taskController.findTaskById(item.taskId) : null;
  final color = isApp ? calendarPriorityColor(item.priority) : Colors.purple;

  return Card(
    margin: const EdgeInsets.only(bottom: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: color.withValues(alpha: 0.5)),
    ),
    child: ListTile(
      leading: Container(
        width: 4,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      title: Text(
        item.title,
        style: TextStyle(
          decoration: item.isCompleted == true
              ? TextDecoration.lineThrough
              : null,
          color: item.isCompleted == true ? Colors.grey : null,
        ),
      ),
      subtitle: Row(
        children: [
          // 来源标签帮助区分本地任务和手机系统日历事件。
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: isApp
                  ? Colors.blue.withValues(alpha: 0.1)
                  : Colors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isApp ? 'APP' : '手机日历',
              style: TextStyle(fontSize: 10, color: color),
            ),
          ),
          if (item.startTime != null) ...[
            const SizedBox(width: 8),
            Text(
              formatCalendarTime(item.startTime!),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ],
      ),
      trailing: isApp
          ? Checkbox(
              value: item.isCompleted ?? false,
              onChanged: linkedTask == null
                  ? null
                  // 完成状态流回任务控制器，奖励和跨模块反馈仍走任务模块原路径。
                  : (_) => taskController.updateTaskStatus(linkedTask),
            )
          : null,
      // 点击卡片打开详情 Sheet，可同步任务到系统日历或查看设备事件。
      onTap: () =>
          showCalendarItemDetail(item, calenderController, taskController),
    ),
  );
}

/// 当天事项列表里的课程卡片。
///
/// 课程数据来自当前学期和日期过滤结果，点击后进入课程详情/冲突详情弹窗。
Widget buildScheduleSessionCalendarCard(
  BuildContext context,
  ScheduleController scheduleController,
  ScheduleSemesterModel semester,
  ScheduleSessionModel session,
  AppThemePalette palette,
) {
  // 颜色和时间范围都复用课表服务，保证月历课程卡与课表网格表现一致。
  final color = ScheduleColorService.colorForSession(session, palette);
  final timeRange = scheduleSessionTimeRange(semester, session);
  final location = scheduleValueOrFallback(session.location);

  return Card(
    margin: const EdgeInsets.only(bottom: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: color.withValues(alpha: 0.5)),
    ),
    child: ListTile(
      leading: Container(
        width: 4,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      title: Text(
        session.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 月历卡片只展示最关键的课程时间和地点，完整信息在详情弹窗中查看。
            _buildScheduleCalendarInfoLine(Icons.schedule, '时间：$timeRange'),
            const SizedBox(height: 2),
            _buildScheduleCalendarInfoLine(Icons.location_on, '地点：$location'),
          ],
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showScheduleSessionDetailDialog(
        context,
        scheduleController,
        [session],
      ),
    ),
  );
}

/// 课程卡片中的一行图标 + 文本信息。
Widget _buildScheduleCalendarInfoLine(IconData icon, String text) {
  return Row(
    children: [
      Icon(icon, size: 14, color: Colors.grey[600]),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
        ),
      ),
    ],
  );
}
