import 'package:todolist/model/schedule/schedule.dart';

class ScheduleTimeService {
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

  static String sectionStartTime(ScheduleSemesterModel semester, int section) {
    if (section < 1 ||
        section >= semester.sessionToTimeMinutes.length ||
        semester.sessionToTimeMinutes[section].isEmpty) {
      return '--:--';
    }
    return formatMinutes(semester.sessionToTimeMinutes[section].first);
  }

  static String sectionEndTime(ScheduleSemesterModel semester, int section) {
    if (section < 1 ||
        section >= semester.sessionToTimeMinutes.length ||
        semester.sessionToTimeMinutes[section].length < 2) {
      return '--:--';
    }
    return formatMinutes(semester.sessionToTimeMinutes[section].last);
  }

  static String formatMinutes(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
