part of '../calendar.dart';

// 当日事项列表
Widget _buildDayList(
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
    final scheduleSessions = _scheduleSessionsForDate(
      scheduleController,
      selected,
    );
    final weekLabel = _scheduleWeekLabelForDate(scheduleController, selected);
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
          (item) => _buildItemCard(item, calenderController, taskController),
        ),
        if (semester != null)
          ...scheduleSessions.map(
            (session) => _buildScheduleSessionCalendarCard(
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
