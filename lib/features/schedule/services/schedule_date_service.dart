import 'package:todolist/model/schedule/schedule.dart';

/// 某个日期在学期课表中的上下文。
///
/// 包含所属半学期、单双周索引和周次，供月历课程过滤和周次标题展示使用。
class ScheduleDayContext {
  final ScheduleSemesterModel semester;
  final int halfIndex;
  final int oddEvenIndex;
  final int weekNumber;

  const ScheduleDayContext({
    required this.semester,
    required this.halfIndex,
    required this.oddEvenIndex,
    required this.weekNumber,
  });

  /// 当前日期是否属于上半学期。
  bool get isFirstHalf => halfIndex == 0;

  /// 半学期展示名，模型未配置时回退为“上半/下半”。
  String get halfName {
    final name = isFirstHalf ? semester.firstHalfName : semester.secondHalfName;
    return name.isEmpty ? (isFirstHalf ? '上半' : '下半') : name;
  }

  /// 月历当天列表顶部展示的周次标签。
  String get weekLabel =>
      '$halfName${ScheduleDateService.chineseNumber(weekNumber)}周';
}

/// 课表日期服务，负责半学期日期表、日期定位和某日课程过滤。
///
/// 这是纯逻辑服务，不访问 GetX、Hive 或 UI；输入学期模型和日期，输出可测试的数据结果。
class ScheduleDateService {
  /// 根据上下半学期起止日期生成 `dayOfWeekToDays` 映射表。
  ///
  /// 结果结构沿用现有 Hive 模型字段，不改变 schema。
  static List<List<List<List<DateTime>>>> buildDayOfWeekToDays({
    required DateTime firstHalfStart,
    required DateTime firstHalfEnd,
    required DateTime secondHalfStart,
    required DateTime secondHalfEnd,
  }) {
    final result = ScheduleSemesterModel.emptyDayOfWeekToDays();
    fillHalfDays(firstHalfStart, firstHalfEnd, result[0]);
    fillHalfDays(secondHalfStart, secondHalfEnd, result[1]);
    return result;
  }

  /// 将一个半学期的日期填入目标结构。
  ///
  /// weekday 使用 Dart 的 1-7，oddEvenWeek 在每周结束后切换，用于推导单双周。
  static void fillHalfDays(
    DateTime start,
    DateTime end,
    List<List<List<DateTime>>> target,
  ) {
    var weekday = start.weekday;
    var oddEvenWeek = 0;
    for (
      var day = start;
      !day.isAfter(end);
      day = day.add(const Duration(days: 1))
    ) {
      target[oddEvenWeek][weekday].add(day);
      weekday++;
      if (weekday == 8) {
        weekday = 1;
        oddEvenWeek = 1 - oddEvenWeek;
      }
    }
  }

  /// 定位某个日期在学期中的上下文。
  ///
  /// 日期不在任一半学期范围内时返回 null，调用方据此隐藏课程或周次标签。
  static ScheduleDayContext? dayContextForDate(
    ScheduleSemesterModel semester,
    DateTime date,
  ) {
    if (date.weekday < 1 || date.weekday > 7) {
      return null;
    }
    final day = dayKey(date);
    for (
      var halfIndex = 0;
      halfIndex < semester.dayOfWeekToDays.length;
      halfIndex++
    ) {
      final half = semester.dayOfWeekToDays[halfIndex];
      for (var oddEvenIndex = 0; oddEvenIndex < half.length; oddEvenIndex++) {
        final weekdayDays = half[oddEvenIndex];
        if (date.weekday >= weekdayDays.length) {
          continue;
        }
        final days = weekdayDays[date.weekday];
        for (var index = 0; index < days.length; index++) {
          if (isSameDay(days[index], day)) {
            return ScheduleDayContext(
              semester: semester,
              halfIndex: halfIndex,
              oddEvenIndex: oddEvenIndex,
              weekNumber: oddEvenIndex == 0 ? index * 2 + 1 : index * 2 + 2,
            );
          }
        }
      }
    }
    return null;
  }

  /// 获取某一天应展示的课程。
  ///
  /// 过滤条件包括：确认状态、是否显示在课表、星期、半学期、单双周和自定义周次。
  static List<ScheduleSessionModel> sessionsForDate(
    ScheduleSemesterModel semester,
    DateTime date,
  ) {
    final context = dayContextForDate(semester, date);
    if (context == null) {
      return <ScheduleSessionModel>[];
    }
    final sessions = semester.sessions.where((session) {
      // 未确认、隐藏、星期不匹配或没有节次的课程不进入当天列表。
      if (!session.confirmed ||
          !session.showOnTimetable ||
          session.dayOfWeek != date.weekday ||
          session.time.isEmpty) {
        return false;
      }
      if (context.isFirstHalf && !session.firstHalf) {
        return false;
      }
      if (!context.isFirstHalf && !session.secondHalf) {
        return false;
      }
      if (session.customRepeat) {
        // 自定义周次优先于单双周规则。
        return session.customRepeatWeeks.contains(context.weekNumber);
      }
      return context.oddEvenIndex == 0 ? session.oddWeek : session.evenWeek;
    }).toList();
    sessions.sort((a, b) => a.time.first.compareTo(b.time.first));
    return sessions;
  }

  /// 归一化日期到当天零点，避免时分秒影响同日判断。
  static DateTime dayKey(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// 判断两个日期是否为同一天。
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 将周次数字转换为中文数字展示。
  ///
  /// 超出常见两位数范围时退回原数字字符串，避免复杂转换引入风险。
  static String chineseNumber(int value) {
    const digits = ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九'];
    if (value <= 0) {
      return value.toString();
    }
    if (value < 10) {
      return digits[value];
    }
    if (value == 10) {
      return '十';
    }
    if (value < 20) {
      return '十${digits[value % 10]}';
    }
    if (value % 10 == 0) {
      return '${digits[value ~/ 10]}十';
    }
    if (value < 100) {
      return '${digits[value ~/ 10]}十${digits[value % 10]}';
    }
    return value.toString();
  }
}
