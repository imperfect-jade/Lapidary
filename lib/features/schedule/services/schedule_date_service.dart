import 'package:todolist/model/schedule/schedule.dart';

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

  bool get isFirstHalf => halfIndex == 0;

  String get halfName {
    final name = isFirstHalf ? semester.firstHalfName : semester.secondHalfName;
    return name.isEmpty ? (isFirstHalf ? '上半' : '下半') : name;
  }

  String get weekLabel =>
      '$halfName${ScheduleDateService.chineseNumber(weekNumber)}周';
}

class ScheduleDateService {
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

  static List<ScheduleSessionModel> sessionsForDate(
    ScheduleSemesterModel semester,
    DateTime date,
  ) {
    final context = dayContextForDate(semester, date);
    if (context == null) {
      return <ScheduleSessionModel>[];
    }
    final sessions = semester.sessions.where((session) {
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
        return session.customRepeatWeeks.contains(context.weekNumber);
      }
      return context.oddEvenIndex == 0 ? session.oddWeek : session.evenWeek;
    }).toList();
    sessions.sort((a, b) => a.time.first.compareTo(b.time.first));
    return sessions;
  }

  static DateTime dayKey(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

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
