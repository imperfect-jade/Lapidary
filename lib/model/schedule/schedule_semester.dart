import 'package:hive/hive.dart';
import 'package:todolist/model/schedule/schedule_session.dart';

part 'schedule_semester.g.dart';

@HiveType(typeId: 5)
class ScheduleSemesterModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  List<ScheduleSessionModel> sessions;

  @HiveField(3)
  List<List<int>> sessionToTimeMinutes;

  @HiveField(4)
  List<List<List<List<DateTime>>>> dayOfWeekToDays;

  @HiveField(5)
  Map<DateTime, String> holidays;

  @HiveField(6)
  Map<DateTime, DateTime> exchanges;

  @HiveField(7)
  DateTime? lastSyncedAt;

  ScheduleSemesterModel({
    required this.id,
    required this.name,
    List<ScheduleSessionModel>? sessions,
    List<List<int>>? sessionToTimeMinutes,
    List<List<List<List<DateTime>>>>? dayOfWeekToDays,
    Map<DateTime, String>? holidays,
    Map<DateTime, DateTime>? exchanges,
    this.lastSyncedAt,
  }) : sessions = sessions ?? <ScheduleSessionModel>[],
       sessionToTimeMinutes =
           sessionToTimeMinutes ?? defaultSessionToTimeMinutes(),
       dayOfWeekToDays = dayOfWeekToDays ?? emptyDayOfWeekToDays(),
       holidays = holidays ?? <DateTime, String>{},
       exchanges = exchanges ?? <DateTime, DateTime>{};

  factory ScheduleSemesterModel.fromCelechronJson(Map<String, dynamic> json) {
    return ScheduleSemesterModel(
      id: json['id'] as String? ?? json['name'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sessions: ((json['sessions'] ?? <dynamic>[]) as List)
          .whereType<Map>()
          .map(
            (value) => ScheduleSessionModel.fromCelechronJson(
              Map<String, dynamic>.from(value),
            ),
          )
          .toList(),
      sessionToTimeMinutes: _sessionToTimeMinutesFromJson(
        json['sessionToTime'],
      ),
      dayOfWeekToDays: _dayOfWeekToDaysFromJson(json['dayOfWeekToDays']),
      holidays: _dateStringMapFromJson(json['holidays']),
      exchanges: _dateDateMapFromJson(json['exchanges']),
      lastSyncedAt: _dateTimeFromJson(json['lastSyncedAt']),
    );
  }

  String get firstHalfName {
    return name.length > 9 ? name.substring(9, 10) : '';
  }

  String get secondHalfName {
    return name.length > 10 ? name.substring(10, 11) : '';
  }

  List<List<ScheduleSessionModel>> get firstHalfTimetable {
    return _sessionsByHalf((session) => session.firstHalf);
  }

  List<List<ScheduleSessionModel>> get secondHalfTimetable {
    return _sessionsByHalf((session) => session.secondHalf);
  }

  double get firstHalfSessionCount {
    return _sessionCount((session) => session.firstHalf);
  }

  double get secondHalfSessionCount {
    return _sessionCount((session) => session.secondHalf);
  }

  DateTime get firstDay {
    try {
      return dayOfWeekToDays.first.first[1].first;
    } catch (_) {
      return DateTime.now();
    }
  }

  DateTime get lastDay {
    try {
      return dayOfWeekToDays.last.last.last.last;
    } catch (_) {
      return DateTime.now();
    }
  }

  void applyZjuCalendarConfig(Map<String, dynamic> json) {
    final startEnd = (json['startEnd'] as List)
        .map((value) => DateTime.parse(value as String))
        .toList();
    sessionToTimeMinutes = (json['sessionTime'] as List)
        .map(
          (row) => (row as List)
              .map((value) => _minutesFromClock(value as String))
              .toList(),
        )
        .toList();
    holidays = ((json['holiday'] ?? <String, dynamic>{}) as Map).map(
      (key, value) => MapEntry(DateTime.parse(key as String), value as String),
    );
    exchanges = ((json['exchange'] ?? <String, dynamic>{}) as Map).map((
      key,
      _,
    ) {
      final exchangeKey = key as String;
      return MapEntry(
        DateTime.parse(exchangeKey.substring(0, 8)),
        DateTime.parse(exchangeKey.substring(8, 16)),
      );
    });
    exchanges.addAll(
      ((json['exchange'] ?? <String, dynamic>{}) as Map).map((key, _) {
        final exchangeKey = key as String;
        return MapEntry(
          DateTime.parse(exchangeKey.substring(8, 16)),
          DateTime.parse(exchangeKey.substring(0, 8)),
        );
      }),
    );

    dayOfWeekToDays = emptyDayOfWeekToDays();
    _fillHalfDays(startEnd[0], startEnd[1], dayOfWeekToDays[0]);
    _fillHalfDays(startEnd[2], startEnd[3], dayOfWeekToDays[1]);
  }

  Map<String, dynamic> toCelechronJson() => {
    'id': id,
    'name': name,
    'sessions': sessions.map((session) => session.toCelechronJson()).toList(),
    'sessionToTime': sessionToTimeMinutes,
    'dayOfWeekToDays': dayOfWeekToDays
        .map(
          (half) => half
              .map(
                (oddEven) => oddEven
                    .map(
                      (days) =>
                          days.map((day) => day.toIso8601String()).toList(),
                    )
                    .toList(),
              )
              .toList(),
        )
        .toList(),
    'holidays': holidays.map(
      (key, value) => MapEntry(key.toIso8601String(), value),
    ),
    'exchanges': exchanges.map(
      (key, value) => MapEntry(key.toIso8601String(), value.toIso8601String()),
    ),
    'lastSyncedAt': lastSyncedAt?.toIso8601String(),
  };

  List<List<ScheduleSessionModel>> _sessionsByHalf(
    bool Function(ScheduleSessionModel session) inHalf,
  ) {
    return sessions
        .where(
          (session) =>
              inHalf(session) && session.confirmed && session.showOnTimetable,
        )
        .fold<List<List<ScheduleSessionModel>>>(
          <List<ScheduleSessionModel>>[[], [], [], [], [], [], [], []],
          (result, session) {
            if (session.dayOfWeek >= 1 && session.dayOfWeek <= 7) {
              result[session.dayOfWeek].add(session);
            }
            return result;
          },
        );
  }

  double _sessionCount(bool Function(ScheduleSessionModel session) inHalf) {
    return sessions
        .where(
          (session) =>
              inHalf(session) && session.confirmed && session.showOnTimetable,
        )
        .fold<double>(
          0,
          (total, session) =>
              total +
              session.time.length *
                  ((session.oddWeek ? 1 : 0) + (session.evenWeek ? 1 : 0)),
        );
  }

  static List<List<int>> defaultSessionToTimeMinutes() {
    const starts = <int>[
      0,
      8 * 60,
      8 * 60 + 50,
      10 * 60,
      10 * 60 + 50,
      11 * 60 + 40,
      13 * 60 + 25,
      14 * 60 + 15,
      15 * 60 + 5,
      16 * 60 + 15,
      17 * 60 + 5,
      18 * 60 + 50,
      19 * 60 + 40,
      20 * 60 + 30,
    ];
    return [
      <int>[],
      for (var i = 1; i < starts.length; i++) <int>[starts[i], starts[i] + 45],
    ];
  }

  static List<List<List<List<DateTime>>>> emptyDayOfWeekToDays() {
    return [
      [
        [[], [], [], [], [], [], [], []],
        [[], [], [], [], [], [], [], []],
      ],
      [
        [[], [], [], [], [], [], [], []],
        [[], [], [], [], [], [], [], []],
      ],
    ];
  }

  static void _fillHalfDays(
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

  static int _minutesFromClock(String value) {
    return int.parse(value.substring(0, 2)) * 60 +
        int.parse(value.substring(3, 5));
  }

  static DateTime? _dateTimeFromJson(Object? value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static List<List<int>> _sessionToTimeMinutesFromJson(Object? value) {
    if (value is! List) {
      return defaultSessionToTimeMinutes();
    }
    return value
        .map(
          (row) => row is List
              ? row
                    .map(
                      (item) =>
                          item is num ? item.toInt() : int.tryParse('$item'),
                    )
                    .whereType<int>()
                    .toList()
              : <int>[],
        )
        .toList();
  }

  static List<List<List<List<DateTime>>>> _dayOfWeekToDaysFromJson(
    Object? value,
  ) {
    if (value is! List) {
      return emptyDayOfWeekToDays();
    }
    return value
        .map(
          (half) => (half as List)
              .map(
                (oddEven) => (oddEven as List)
                    .map(
                      (days) => (days as List)
                          .map(_dateTimeFromJson)
                          .whereType<DateTime>()
                          .toList(),
                    )
                    .toList(),
              )
              .toList(),
        )
        .toList();
  }

  static Map<DateTime, String> _dateStringMapFromJson(Object? value) {
    if (value is! Map) {
      return <DateTime, String>{};
    }
    return value.map((key, item) {
      final date = _dateTimeFromJson(key) ?? DateTime.now();
      return MapEntry(date, item as String);
    });
  }

  static Map<DateTime, DateTime> _dateDateMapFromJson(Object? value) {
    if (value is! Map) {
      return <DateTime, DateTime>{};
    }
    return value.map((key, item) {
      final date = _dateTimeFromJson(key) ?? DateTime.now();
      final target = _dateTimeFromJson(item) ?? date;
      return MapEntry(date, target);
    });
  }
}
