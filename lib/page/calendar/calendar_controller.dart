import 'package:get/get.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:todolist/model/calendar/calendar.dart';
import 'package:todolist/model/task/task.dart';

/// 系统日历控制器，负责权限、默认日历选择、设备事件读取和任务同步。
///
/// 它只管理手机系统日历相关能力，并把本地任务/设备事件聚合成日历事项；
/// 任务增删改仍由 `TaskController` 负责，课表课程由 `ScheduleController` 负责。
class CalendarController extends GetxController {
  final _deviceCalendarPlugin = DeviceCalendarPlugin();

  // 系统日历状态：权限、选中的设备日历、当前选中日期和当天设备事件缓存。
  final hasPermission = false.obs;
  final calendarId = RxnString(); // 选中的日历ID
  final selectedDate = DateTime.now().obs;
  final deviceEvents = <Event>[].obs; // 手机日历事件
  final deviceEventsDate = Rxn<DateTime>();

  /// 暴露插件实例供极少数需要直接访问系统日历 API 的场景使用。
  DeviceCalendarPlugin get plugin => _deviceCalendarPlugin;

  @override
  void onInit() {
    super.onInit();
    // 应用初始化阶段注册该控制器后会立即请求权限，保持原有权限请求时机。
    requestPermission();
  }

  /// 请求系统日历权限。
  ///
  /// 授权成功后选择默认可写日历；拒绝或永久拒绝时只提示用户，不修改本地任务数据。
  Future<void> requestPermission() async {
    // 申请完整日历访问权限，后续读取事件和创建事件都依赖它。
    final PermissionStatus status = await Permission.calendarFullAccess
        .request();

    // 权限状态驱动日历同步入口可用性。
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

  /// 获取默认系统日历。
  ///
  /// 优先选择可写日历，保证“同步任务到手机日历”能创建事件；没有可写项时退到第一项。
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

  /// 读取指定日期的手机系统日历事件。
  ///
  /// 读取前会清空旧缓存并记录日期 key，避免切换日期后继续展示上一天的设备事件。
  Future<void> loadDeviceEvents(DateTime date) async {
    deviceEvents.clear();
    deviceEventsDate.value = _dayKey(date);
    if (!hasPermission.value || calendarId.value == null) return;

    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    // 调用系统日历插件读取选中日期范围内的事件。
    final result = await _deviceCalendarPlugin.retrieveEvents(
      calendarId.value!, // 选中的日历ID
      RetrieveEventsParams(startDate: start, endDate: end), // 指定日期
    );

    if (result.isSuccess && result.data != null) {
      deviceEvents.value = result.data!.toList();
    }
  }

  /// 将本地任务同步为手机系统日历事件。
  ///
  /// 若权限或日历缺失，会先尝试重新请求权限；返回值只表示系统日历写入是否成功。
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
    // 调用创建或更新事件方法；本地任务模型不在这里写入系统事件 id。
    final result = await _deviceCalendarPlugin.createOrUpdateEvent(event);
    return result?.isSuccess ?? false;
  }

  /// 从手机系统日历删除指定事件。
  ///
  /// 该方法只删除设备日历事件，不删除本地任务或课表课程。
  Future<bool> deleteFromCalendar(String eventId) async {
    if (!hasPermission.value || calendarId.value == null) return false;
    // 调用设备日历插件删除事件，失败时由调用方决定是否提示。
    final result = await _deviceCalendarPlugin.deleteEvent(
      calendarId.value!,
      eventId,
    );
    return result.isSuccess;
  }

  /// 获取某天的所有月历事项。
  ///
  /// 输入的 tasks 已由任务控制器按日期过滤；这里再合并同一天的设备日历事件，
  /// 输出统一的 `CalendarModel` 供当天事项列表展示。
  List<CalendarModel> getItemsForDate(DateTime date, List<TaskModel> tasks) {
    final items = <CalendarModel>[];

    // APP 任务按 deadline 归入当天事项，完成状态仍回到 TaskController 处理。
    for (final task in tasks) {
      if (task.deadline.year == date.year &&
          task.deadline.month == date.month &&
          task.deadline.day == date.day) {
        items.add(CalendarModel.fromTask(task));
      }
    }

    // 只在设备事件缓存日期和当前日期一致时合并，避免异步读取后串到其他日期。
    if (_isSameDay(deviceEventsDate.value, date)) {
      for (final event in deviceEvents) {
        items.add(CalendarModel.fromDeviceEvent(event));
      }
    }

    return items;
  }

  /// 归一化日期到当天零点，用作设备事件缓存 key。
  DateTime _dayKey(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// 判断两个日期是否是同一天，忽略时分秒。
  bool _isSameDay(DateTime? a, DateTime b) {
    return a != null &&
        a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }
}
