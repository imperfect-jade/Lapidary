part of '../calendar.dart';

// 日历视图
Widget _buildCalendar(
  CalendarController calenderController,
  TaskController taskController,
  ScheduleController scheduleController,
) {
  return Obx(() {
    final selected = calenderController.selectedDate.value;
    final palette = Get.isRegistered<ThemeController>()
        ? Get.find<ThemeController>().currentPalette
        : TaskTheme.palette;

    return TableCalendar<Object>(
      firstDay: DateTime(2024, 1, 1),
      lastDay: DateTime(2027, 12, 31),
      focusedDay: selected,
      selectedDayPredicate: (day) => isSameDay(selected, day),

      // 点击日期
      onDaySelected: (selected, focused) {
        calenderController.selectedDate.value = selected;
        calenderController.loadDeviceEvents(selected);
      },

      // 有任务或课程的日期下方显示标记点
      eventLoader: (day) {
        return <Object>[
          ...taskController.tasksForDay(day),
          ..._scheduleSessionsForDate(scheduleController, day),
        ];
      },

      // 样式
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        selectedDecoration: const BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        markerDecoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        markersMaxCount: 4,
      ),

      calendarBuilders: CalendarBuilders<Object>(
        markerBuilder: (context, day, events) {
          if (events.isEmpty) {
            return null;
          }
          return _buildCalendarMarkers(events, palette);
        },
      ),

      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
    );
  });
}

Widget _buildCalendarMarkers(List<Object> events, AppThemePalette palette) {
  final visibleEvents = events.take(4).toList();
  return Positioned(
    bottom: 4,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: visibleEvents
          .map(
            (event) => Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: _calendarMarkerColor(event, palette),
                shape: BoxShape.circle,
              ),
            ),
          )
          .toList(),
    ),
  );
}

Color _calendarMarkerColor(Object event, AppThemePalette palette) {
  if (event is ScheduleSessionModel) {
    return ScheduleColorService.colorForSession(event, palette);
  }
  if (event is TaskModel) {
    return CalendarPage._priorityColors[event.priority] ?? Colors.grey;
  }
  return Colors.grey;
}
