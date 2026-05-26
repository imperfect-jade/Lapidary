// 日历页面
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/features/schedule/services/schedule_color_service.dart';
import 'package:todolist/features/schedule/services/schedule_date_service.dart';
import 'package:todolist/features/schedule/services/schedule_layout_service.dart';
import 'package:todolist/features/schedule/services/schedule_time_service.dart';
import 'package:todolist/model/calendar/calendar.dart';
import 'package:todolist/model/schedule/schedule.dart';
import 'package:todolist/model/task/task.dart';
import 'package:todolist/page/calendar/calendar_controller.dart';
import 'package:todolist/page/schedule/schedule_controller.dart';
import 'package:todolist/page/task/task_controller.dart';

part 'dialogs/schedule_semester_dialog.dart';
part 'dialogs/schedule_session_dialog.dart';
part 'sheets/schedule_session_sheet.dart';
part 'sheets/item_detail_sheet.dart';
part 'utils/formatters.dart';
part 'utils/schedule_calendar_helpers.dart';
part 'widgets/calendar_item_card.dart';
part 'widgets/calendar_view.dart';
part 'widgets/day_item_list.dart';
part 'widgets/schedule_view.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  // 优先级颜色
  static const _priorityColors = {
    1: Colors.red,
    2: Colors.orange,
    3: Colors.blue,
    4: Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    final calenderController = Get.find<CalendarController>();
    final scheduleController = Get.find<ScheduleController>();

    return Scaffold(
      backgroundColor: TaskTheme.primaryColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: TaskTheme.appBarColor,
        foregroundColor: Colors.black,
        title: const Text('日历'),
        actions: [
          Obx(
            () => IconButton(
              tooltip:
                  scheduleController.viewMode.value ==
                      CalendarContentView.schedule
                  ? '切换到月历'
                  : '切换到课表',
              icon: Icon(
                scheduleController.viewMode.value ==
                        CalendarContentView.schedule
                    ? Icons.calendar_month
                    : Icons.view_week,
              ),
              onPressed: () {
                final target =
                    scheduleController.viewMode.value ==
                        CalendarContentView.schedule
                    ? CalendarContentView.month
                    : CalendarContentView.schedule;
                scheduleController.changeViewMode(target);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _buildScheduleFloatingActionButton(
        context,
        scheduleController,
      ),
      body: Obx(() {
        if (scheduleController.viewMode.value == CalendarContentView.schedule) {
          return _buildScheduleView(context, scheduleController);
        }
        return GetBuilder<TaskController>(
          id: 'calendar',
          builder: (taskController) {
            return Column(
              children: [
                _buildCalendar(
                  calenderController,
                  taskController,
                  scheduleController,
                ),
                const Divider(height: 1),
                Expanded(
                  child: _buildDayList(
                    context,
                    calenderController,
                    taskController,
                    scheduleController,
                  ),
                ),
              ],
            );
          },
        );
      }),
    );
  }
}
