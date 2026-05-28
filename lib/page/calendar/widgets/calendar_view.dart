import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/features/schedule/services/schedule_color_service.dart';
import 'package:todolist/model/schedule/schedule.dart';
import 'package:todolist/model/task/task.dart';
import 'package:todolist/page/calendar/calendar_controller.dart';
import 'package:todolist/page/calendar/utils/formatters.dart';
import 'package:todolist/page/calendar/utils/schedule_calendar_helpers.dart';
import 'package:todolist/page/schedule/schedule_controller.dart';
import 'package:todolist/page/task/task_controller.dart';

/// 月历视图，展示日期网格和任务/课程 marker。
///
/// 日期选择写入 `CalendarController.selectedDate` 并触发系统日历事件读取；
/// marker 同时来自任务截止日期和课表课程，不在这里修改任务或课表数据。
Widget buildCalendarView(
  CalendarController calenderController,
  TaskController taskController,
  ScheduleController scheduleController,
) {
  return Obx(() {
    // 选中日期驱动 focusedDay/selectedDay，主题色用于课程 marker 配色。
    final selected = calenderController.selectedDate.value;
    final palette = Get.isRegistered<ThemeController>()
        ? Get.find<ThemeController>().currentPalette
        : TaskTheme.palette;

    return TableCalendar<Object>(
      firstDay: DateTime(2024, 1, 1),
      lastDay: DateTime(2027, 12, 31),
      focusedDay: selected,
      selectedDayPredicate: (day) => isSameDay(selected, day),

      // 点击日期会切换当天事项列表，并异步刷新该日手机日历事件。
      onDaySelected: (selected, focused) {
        calenderController.selectedDate.value = selected;
        calenderController.loadDeviceEvents(selected);
      },

      // 有任务或课程的日期下方显示标记点，TableCalendar 只关心非空事件列表。
      eventLoader: (day) {
        return <Object>[
          ...taskController.tasksForDay(day),
          ...scheduleSessionsForDate(scheduleController, day),
        ];
      },

      // 月历基础样式，marker 颜色由自定义 markerBuilder 决定。
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
          // 最多展示 4 个点，任务按优先级配色，课程按课表颜色算法配色。
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

/// 构建日期格下方的小圆点 marker。
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

/// 根据事项类型返回 marker 颜色。
///
/// 课程使用稳定 hash 色，任务使用优先级色，未知类型退回灰色。
Color _calendarMarkerColor(Object event, AppThemePalette palette) {
  if (event is ScheduleSessionModel) {
    return ScheduleColorService.colorForSession(event, palette);
  }
  if (event is TaskModel) {
    return calendarPriorityColor(event.priority);
  }
  return Colors.grey;
}
