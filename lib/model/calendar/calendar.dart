// 日历数据模型
// 统一的数据模型，把APP任务和手机日历事件统一展示
import 'package:device_calendar/device_calendar.dart';
import 'package:todolist/model/task/task.dart';

class CalendarModel {
  final String id;
  final String title;
  final String? description;
  final DateTime? startTime;
  final String source; // 'app' 或 'device'
  final String? taskId; // APP任务的ID
  final String? eventId; // 手机日历事件ID
  final int? priority; // APP任务优先级
  final bool? isCompleted;

  CalendarModel({
    required this.id,
    required this.title,
    this.description,
    this.startTime,
    required this.source,
    this.taskId,
    this.eventId,
    this.priority,
    this.isCompleted,
  });
  // 从APP任务创建CalendarModel
  factory CalendarModel.fromTask(TaskModel task) => CalendarModel(
    id: 'app_${task.id}',
    title: task.title,
    description: task.description,
    startTime: task.deadline,
    source: 'app',
    taskId: task.id,
    priority: task.priority,
    isCompleted: task.isCompleted,
  );
  // 从手机日历事件创建CalendarModel
  factory CalendarModel.fromDeviceEvent(Event event) => CalendarModel(
    id: 'device_${event.eventId}',
    title: event.title ?? '未命名事件',
    description: event.description,
    startTime: event.start,
    source: 'device',
    eventId: event.eventId,
  );
}
