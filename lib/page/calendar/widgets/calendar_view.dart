part of '../calendar.dart';

// 日历视图
Widget _buildCalendar(
  CalendarController calenderController,
  TaskController taskController,
) {
  return Obx(() {
    final selected = calenderController.selectedDate.value;

    return TableCalendar(
      firstDay: DateTime(2024, 1, 1),
      lastDay: DateTime(2027, 12, 31),
      focusedDay: selected,
      selectedDayPredicate: (day) => isSameDay(selected, day),

      // 点击日期
      onDaySelected: (selected, focused) {
        calenderController.selectedDate.value = selected;
        calenderController.loadDeviceEvents(selected);
      },

      // 有任务的日期下方显示标记点
      eventLoader: (day) {
        return taskController.tasksForDay(day);
      },

      // 样式
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.3),
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
        markersMaxCount: 3,
      ),

      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
    );
  });
}
