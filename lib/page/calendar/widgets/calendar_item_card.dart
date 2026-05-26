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

// 单个事项卡片
Widget buildCalendarItemCard(
  CalendarModel item,
  CalendarController calenderController,
  TaskController taskController,
) {
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
          // 来源标签
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
                  : (_) => taskController.updateTaskStatus(linkedTask),
            )
          : null,
      // 点击事件显示详情
      onTap: () =>
          showCalendarItemDetail(item, calenderController, taskController),
    ),
  );
}

Widget buildScheduleSessionCalendarCard(
  BuildContext context,
  ScheduleController scheduleController,
  ScheduleSemesterModel semester,
  ScheduleSessionModel session,
  AppThemePalette palette,
) {
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
