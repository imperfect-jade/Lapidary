// 日历页面
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/model/calendar/calendar.dart';
import 'package:todolist/page/calendar/calendar_controller.dart';
import 'package:todolist/page/task/task_controller.dart';

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

  // 单个事项卡片
  Widget _buildItemCard(
    CalendarModel item,
    CalendarController calenderController,
    TaskController taskController,
  ) {
    final isApp = item.source == 'app';
    final color = isApp
        ? (_priorityColors[item.priority] ?? Colors.grey)
        : Colors.purple;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withOpacity(0.5)),
      ),
      child: ListTile(
        leading: Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            decoration: item.isCompleted == true
                ? TextDecoration.lineThrough
                : null,
            color: item.isCompleted == true ? Colors.grey : null,
          ),
        ),
        subtitle: Row(
          children: [
            // 来源标签
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isApp
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isApp ? 'APP' : '手机日历',
                style: TextStyle(fontSize: 10, color: color),
              ),
            ),
            if (item.startTime != null) ...[
              const SizedBox(width: 8),
              Text(
                _formatTime(item.startTime!), //TODO: 时间显示待修改
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ],
        ),
        trailing: isApp
            ? Checkbox(
                value: item.isCompleted ?? false,
                onChanged: (_) {
                  final task = taskController.taskList.firstWhere(
                    (t) => t.id == item.taskId,
                  );
                  taskController.updateTaskStatus(task);
                },
              )
            : null,
        // 点击事件显示详情
        onTap: () => _showItemDetail(item, calenderController, taskController),
      ),
    );
  }

  // 事项详情
  void _showItemDetail(
    CalendarModel item,
    CalendarController calenderController,
    TaskController taskController,
  ) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (item.description != null && item.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                item.description!,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
            const SizedBox(height: 12),
            // 如果是APP任务，提供同步到手机日历的选项
            if (item.source == 'app') ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.sync, color: Colors.blue),
                title: const Text('同步到手机日历'),
                subtitle: const Text('将该任务添加到手机系统日历'),
                onTap: () async {
                  //同步任务到手机日历
                  final task = taskController.taskList.firstWhere(
                    (t) => t.id == item.taskId,
                  );
                  final success = await calenderController.syncTaskToCalendar(
                    task,
                  );
                  Get.back();
                  Get.snackbar(
                    success ? '同步成功' : '同步失败',
                    success ? '已添加到手机日历' : '请检查日历权限',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('删除任务'),
                onTap: () {
                  final task = taskController.taskList.firstWhere(
                    (t) => t.id == item.taskId,
                  );
                  taskController.deleteTask(task);
                  Get.back();
                },
              ),
            ],
            // 如果是手机日历事件
            if (item.source == 'device') ...[
              const Divider(),
              const Text(
                '来自手机日历',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              if (item.startTime != null)
                Text('时间：${_formatDateTime(item.startTime!)}'),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.month}月${dt.day}日 ${_formatTime(dt)}';
  }
}
