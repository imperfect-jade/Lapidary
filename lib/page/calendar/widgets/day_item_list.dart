part of '../calendar.dart';

// 当日事项列表
Widget _buildDayList(
  CalendarController calenderController,
  TaskController taskController,
) {
  return Obx(() {
    final selected = calenderController.selectedDate.value;
    final items = calenderController.getItemsForDate(
      selected,
      taskController.tasksForDay(selected),
    );

    if (items.isEmpty) {
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

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildItemCard(item, calenderController, taskController);
      },
    );
  });
}
