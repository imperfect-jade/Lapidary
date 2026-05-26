import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/page/calendar/calendar_controller.dart';
import 'package:todolist/page/calendar/utils/schedule_calendar_helpers.dart';
import 'package:todolist/page/calendar/widgets/calendar_item_card.dart';
import 'package:todolist/page/schedule/schedule_controller.dart';
import 'package:todolist/page/task/task_controller.dart';

// 当日事项列表
Widget buildDayItemList(
  BuildContext context,
  CalendarController calenderController,
  TaskController taskController,
  ScheduleController scheduleController,
) {
  return Obx(() {
    final selected = calenderController.selectedDate.value;
    final items = calenderController.getItemsForDate(
      selected,
      taskController.tasksForDay(selected),
    );
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
        if (weekLabel != null) _buildScheduleWeekHeader(weekLabel),
        if (items.isEmpty && scheduleSessions.isEmpty)
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
          (item) =>
              buildCalendarItemCard(item, calenderController, taskController),
        ),
        if (semester != null)
          ...scheduleSessions.map(
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

Widget _buildScheduleWeekHeader(String weekLabel) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
    child: Text(
      weekLabel,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
    ),
  );
}
