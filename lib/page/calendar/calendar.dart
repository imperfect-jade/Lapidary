import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/page/calendar/calendar_controller.dart';
import 'package:todolist/page/schedule/schedule_controller.dart';
import 'package:todolist/page/task/task_controller.dart';

import 'widgets/calendar_view.dart';
import 'widgets/day_item_list.dart';
import 'widgets/schedule_view.dart';

/// 日历页入口，统一承载月历事项视图和课表视图。
///
/// 页面通过 `CalendarController` 读取系统日历事件，通过 `ScheduleController`
/// 切换月历/课表并管理学期课表；本页不直接写 Hive 或修改任务数据。
class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 日历控制器负责系统日历权限和设备事件，课表控制器负责视图模式和课程数据。
    final calenderController = Get.find<CalendarController>();
    final scheduleController = Get.find<ScheduleController>();

    return Scaffold(
      // 页面背景沿用任务主题色，月历和课表子视图只负责各自内容区域。
      backgroundColor: TaskTheme.primaryColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: TaskTheme.appBarColor,
        foregroundColor: Colors.black,
        title: const Text('日历'),
        actions: [
          Obx(
            // 右上角按钮在月历和课表之间切换，只改 ScheduleController.viewMode。
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
      // 课表模式下显示创建学期/添加课程入口；月历模式返回空占位。
      floatingActionButton: buildScheduleFloatingActionButton(
        context,
        scheduleController,
      ),
      body: Obx(() {
        // 课表视图和月历视图互斥，避免两个复杂视图同时构建和抢占状态。
        if (scheduleController.viewMode.value == CalendarContentView.schedule) {
          return buildScheduleView(context, scheduleController);
        }
        // 月历中的任务事项需要监听 TaskController 的 calendar 局部刷新。
        return GetBuilder<TaskController>(
          id: 'calendar',
          builder: (taskController) {
            return Column(
              children: [
                // 上半部分是 TableCalendar，marker 同时包含任务和当天课程。
                buildCalendarView(
                  calenderController,
                  taskController,
                  scheduleController,
                ),
                const Divider(height: 1),
                Expanded(
                  // 下半部分展示选中日期的任务、系统日历事项和课程列表。
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
