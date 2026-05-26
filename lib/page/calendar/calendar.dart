// 日历页面
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/page/calendar/calendar_controller.dart';
import 'package:todolist/page/schedule/schedule_controller.dart';
import 'package:todolist/page/task/task_controller.dart';

import 'widgets/calendar_view.dart';
import 'widgets/day_item_list.dart';
import 'widgets/schedule_view.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

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
      floatingActionButton: buildScheduleFloatingActionButton(
        context,
        scheduleController,
      ),
      body: Obx(() {
        if (scheduleController.viewMode.value == CalendarContentView.schedule) {
          return buildScheduleView(context, scheduleController);
        }
        return GetBuilder<TaskController>(
          id: 'calendar',
          builder: (taskController) {
            return Column(
              children: [
                buildCalendarView(
                  calenderController,
                  taskController,
                  scheduleController,
                ),
                const Divider(height: 1),
                Expanded(
                  child: buildDayItemList(
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
