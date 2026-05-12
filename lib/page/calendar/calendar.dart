// 日历页面
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/model/calendar/calendar.dart';
import 'package:todolist/page/calendar/calendar_controller.dart';
import 'package:todolist/page/task/task_controller.dart';

part 'sheets/item_detail_sheet.dart';
part 'utils/formatters.dart';
part 'widgets/calendar_item_card.dart';
part 'widgets/calendar_view.dart';
part 'widgets/day_item_list.dart';

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

    return Scaffold(
      backgroundColor: TaskTheme.primaryColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: TaskTheme.appBarColor,
        foregroundColor: Colors.black,
        title: const Text('日历'),
        actions: [
          // 同步权限状态
          Obx(
            () => IconButton(
              icon: Icon(
                calenderController.hasPermission.value
                    ? Icons.sync
                    : Icons.sync_disabled,
              ),
              onPressed: () => calenderController.requestPermission(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 日历组件
          Expanded(
            child: GetBuilder<TaskController>(
              id: 'calendar',
              builder: (taskController) {
                return Column(
                  children: [
                    _buildCalendar(calenderController, taskController),
                    const Divider(height: 1),
                    Expanded(
                      child: _buildDayList(calenderController, taskController),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
