import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/page/calendar/calendar_controller.dart';
import 'package:todolist/page/calendar/utils/schedule_calendar_helpers.dart';
import 'package:todolist/page/calendar/widgets/calendar_item_card.dart';
import 'package:todolist/page/schedule/schedule_controller.dart';
import 'package:todolist/page/task/task_controller.dart';

/// 选中日期的事项列表。
///
/// 列表合并三类内容：APP 任务、手机系统日历事件和课表课程；
/// 这里只负责展示和进入详情，任务完成/课程编辑仍委托对应 Controller。
Widget buildDayItemList(
  BuildContext context,
  CalendarController calenderController,
  TaskController taskController,
  ScheduleController scheduleController,
) {
  return Obx(() {
    // selectedDate 是月历点击后的单一来源，列表随它响应式切换。
    final selected = calenderController.selectedDate.value;
    // CalendarController 负责聚合 APP 任务和设备日历事件为统一事项模型。
    final items = calenderController.getItemsForDate(
      selected,
      taskController.tasksForDay(selected),
    );
    // 课表课程通过 helper 委托给 ScheduleDateService，不在列表里重复过滤逻辑。
    final scheduleSessions = scheduleSessionsForDate(
      scheduleController,
      selected,
    );
    final weekLabel = scheduleWeekLabelForDate(scheduleController, selected);
    final semester = scheduleController.selectedSemester;
    final palette = Get.isRegistered<ThemeController>()
        ? Get.find<ThemeController>().currentPalette
        : TaskTheme.palette;

    if (items.isEmpty && scheduleSessions.isEmpty && weekLabel == null) {
      // 完全没有任务、设备事件、课程和周次标签时展示居中空状态。
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text('当天没有事项', style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // 有课表上下文时展示“上半/下半 + 第几周”，帮助用户理解课程匹配来源。
        if (weekLabel != null) _buildScheduleWeekHeader(weekLabel),
        if (items.isEmpty && scheduleSessions.isEmpty)
          // 仍有周次标签但当天无事项时，空状态放在列表中部而不是替换整个列表。
          Padding(
            padding: const EdgeInsets.only(top: 48),
            child: Column(
              children: [
                Icon(Icons.event_available, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 8),
                Text('当天没有事项', style: TextStyle(color: Colors.grey[400])),
              ],
            ),
          ),
        ...items.map(
          // 任务和设备日历事件使用统一 CalendarModel 卡片展示。
          (item) =>
              buildCalendarItemCard(item, calenderController, taskController),
        ),
        if (semester != null)
          ...scheduleSessions.map(
            // 课程卡片需要当前学期计算时间范围，并复用课表主题配色。
            (session) => buildScheduleSessionCalendarCard(
              context,
              scheduleController,
              semester,
              session,
              palette,
            ),
          ),
      ],
    );
  });
}

/// 当天事项列表顶部的课表周次标题。
Widget _buildScheduleWeekHeader(String weekLabel) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
    child: Text(
      weekLabel,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
    ),
  );
}
