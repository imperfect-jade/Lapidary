import 'package:todolist/model/schedule/schedule.dart';

/// 课表时间服务，负责节次起止时间和课程时间范围格式化。
///
/// 这是纯展示逻辑，不修改学期模型；缺失或越界节次统一返回 fallback 文案。
class ScheduleTimeService {
  /// 根据课程节次列表格式化完整时间范围。
  ///
  /// 没有节次时返回“未设置时间”，供详情页和月历课程卡展示。
  static String sessionTimeRange(
    ScheduleSemesterModel semester,
    ScheduleSessionModel session,
  ) {
    if (session.time.isEmpty) {
      return '未设置时间';
    }
    final start = sectionStartTime(semester, session.time.first);
    final end = sectionEndTime(semester, session.time.last);
    return '$start - $end';
  }

  /// 获取某节课的开始时间，节次越界或未配置时返回 `--:--`。
  static String sectionStartTime(ScheduleSemesterModel semester, int section) {
    if (section < 1 ||
        section >= semester.sessionToTimeMinutes.length ||
        semester.sessionToTimeMinutes[section].isEmpty) {
      return '--:--';
    }
    return formatMinutes(semester.sessionToTimeMinutes[section].first);
  }

  /// 获取某节课的结束时间，节次越界或缺少结束分钟时返回 `--:--`。
  static String sectionEndTime(ScheduleSemesterModel semester, int section) {
    if (section < 1 ||
        section >= semester.sessionToTimeMinutes.length ||
        semester.sessionToTimeMinutes[section].length < 2) {
      return '--:--';
    }
    return formatMinutes(semester.sessionToTimeMinutes[section].last);
  }

  /// 将一天内分钟数格式化为 `HH:mm`。
  static String formatMinutes(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
