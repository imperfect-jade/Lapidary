//日历控制器
import 'package:get/get.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:todolist/model/calendar/calendar.dart';
import 'package:todolist/model/task/task.dart';

class CalendarController extends GetxController {
  final _deviceCalendarPlugin = DeviceCalendarPlugin();

  // 状态
  final hasPermission = false.obs;
  final calendarId = RxnString(); // 选中的日历ID
  final selectedDate = DateTime.now().obs;
  final deviceEvents = <Event>[].obs; // 手机日历事件
  final deviceEventsDate = Rxn<DateTime>();

  // 插件实例
  DeviceCalendarPlugin get plugin => _deviceCalendarPlugin;

  @override
  void onInit() {
    super.onInit();
    requestPermission();
  }

  // 获取系统日历权限
  Future<void> requestPermission() async {
    // 申请权限
    final PermissionStatus status = await Permission.calendarFullAccess
        .request();

    // 更新权限状态
    hasPermission.value = status.isGranted;

    if (status.isGranted) {
      await _getDefaultCalendar();
    } else if (status.isDenied) {
      // 用户拒绝权限 → 给提示（可选，但体验更好）
      Get.snackbar("提示", "请开启日历权限，才能同步任务到系统日历");
    } else if (status.isPermanentlyDenied) {
      // 永久拒绝 → 跳设置
      Get.snackbar("提示", "日历权限已被永久拒绝，请去设置开启");
      await openAppSettings();
    }
  }

  // 获取默认日历
  Future<void> _getDefaultCalendar() async {
    final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();

    if (calendarsResult.isSuccess && calendarsResult.data != null) {
      // 优先选可写的日历
      final writable = calendarsResult.data!.where(
        (c) => c.isReadOnly == false,
      );

      if (writable.isNotEmpty) {
        calendarId.value = writable.first.id;
      } else if (calendarsResult.data!.isNotEmpty) {
        calendarId.value = calendarsResult.data!.first.id;
      }
    }
  }

  // 读取手机日历事件
  Future<void> loadDeviceEvents(DateTime date) async {
    deviceEvents.clear();
    deviceEventsDate.value = _dayKey(date);
    if (!hasPermission.value || calendarId.value == null) return;

    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    //调用读取日历时间方法，获取指定日期的事件
    final result = await _deviceCalendarPlugin.retrieveEvents(
      calendarId.value!, // 选中的日历ID
      RetrieveEventsParams(startDate: start, endDate: end), // 指定日期
    );

    if (result.isSuccess && result.data != null) {
      deviceEvents.value = result.data!.toList();
    }
  }

  // 同步任务到手机日历
  Future<bool> syncTaskToCalendar(TaskModel task) async {
    if (!hasPermission.value || calendarId.value == null) {
      await requestPermission();
      if (!hasPermission.value) return false;
    }

    final event = Event(
      calendarId.value,
      title: task.title,
      description: task.description ?? '',
      start: TZDateTime.from(task.createdAt, local),
      end: TZDateTime.from(task.deadline, local),
    );
    //调用创建或更新事件方法
    final result = await _deviceCalendarPlugin.createOrUpdateEvent(event);
    return result?.isSuccess ?? false;
  }

  // 从手机日历删除
  Future<bool> deleteFromCalendar(String eventId) async {
    if (!hasPermission.value || calendarId.value == null) return false;
    //调用删除事件方法
    final result = await _deviceCalendarPlugin.deleteEvent(
      calendarId.value!,
      eventId,
    );
    return result.isSuccess;
  }

  // 获取某天的所有事项（APP任务 + 手机日历）
  List<CalendarModel> getItemsForDate(DateTime date, List<TaskModel> tasks) {
    final items = <CalendarModel>[];

    // APP任务
    for (final task in tasks) {
      if (task.deadline.year == date.year &&
          task.deadline.month == date.month &&
          task.deadline.day == date.day) {
        items.add(CalendarModel.fromTask(task));
      }
    }

    // 手机日历事件
    if (_isSameDay(deviceEventsDate.value, date)) {
      for (final event in deviceEvents) {
        items.add(CalendarModel.fromDeviceEvent(event));
      }
    }

    return items;
  }

  DateTime _dayKey(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime? a, DateTime b) {
    return a != null &&
        a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }
}
