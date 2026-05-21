part of '../calendar.dart';

class _ScheduleDayContext {
  final ScheduleSemesterModel semester;
  final int halfIndex;
  final int oddEvenIndex;
  final int weekNumber;

  const _ScheduleDayContext({
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

  String get weekLabel => '$halfName${_chineseNumber(weekNumber)}周';
}

List<ScheduleSessionModel> _scheduleSessionsForDate(
  ScheduleController controller,
  DateTime date,
) {
  final context = _scheduleDayContextForDate(controller, date);
  if (context == null) {
    return <ScheduleSessionModel>[];
  }
  final sessions = context.semester.sessions.where((session) {
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

String? _scheduleWeekLabelForDate(
  ScheduleController controller,
  DateTime date,
) {
  return _scheduleDayContextForDate(controller, date)?.weekLabel;
}

_ScheduleDayContext? _scheduleDayContextForDate(
  ScheduleController controller,
  DateTime date,
) {
  final semester = controller.selectedSemester;
  if (semester == null || date.weekday < 1 || date.weekday > 7) {
    return null;
  }
  final day = _scheduleDayKey(date);
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
        if (_isScheduleSameDay(days[index], day)) {
          return _ScheduleDayContext(
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

String _scheduleSessionTimeRange(
  ScheduleSemesterModel semester,
  ScheduleSessionModel session,
) {
  if (session.time.isEmpty) {
    return '未设置时间';
  }
  final start = _scheduleSectionStartTime(semester, session.time.first);
  final end = _scheduleSectionEndTime(semester, session.time.last);
  return '$start - $end';
}

String _scheduleSectionStartTime(ScheduleSemesterModel semester, int section) {
  if (section < 1 ||
      section >= semester.sessionToTimeMinutes.length ||
      semester.sessionToTimeMinutes[section].isEmpty) {
    return '--:--';
  }
  return _formatMinutes(semester.sessionToTimeMinutes[section].first);
}

String _scheduleSectionEndTime(ScheduleSemesterModel semester, int section) {
  if (section < 1 ||
      section >= semester.sessionToTimeMinutes.length ||
      semester.sessionToTimeMinutes[section].length < 2) {
    return '--:--';
  }
  return _formatMinutes(semester.sessionToTimeMinutes[section].last);
}

DateTime _scheduleDayKey(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

bool _isScheduleSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _chineseNumber(int value) {
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
