import 'package:hive/hive.dart';

part 'schedule_session.g.dart';

@HiveType(typeId: 4)
class ScheduleSessionModel extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String teacher;

  @HiveField(3)
  String? teacherId;

  @HiveField(4)
  String? location;

  @HiveField(5)
  bool confirmed;

  @HiveField(6)
  int dayOfWeek;

  @HiveField(7)
  List<int> time;

  @HiveField(8)
  bool firstHalf;

  @HiveField(9)
  bool secondHalf;

  @HiveField(10)
  bool oddWeek;

  @HiveField(11)
  bool evenWeek;

  @HiveField(12)
  bool customRepeat;

  @HiveField(13)
  List<int> customRepeatWeeks;

  @HiveField(14)
  double? credit;

  @HiveField(15)
  bool? online;

  @HiveField(16)
  String? type;

  ScheduleSessionModel({
    this.id,
    required this.name,
    required this.teacher,
    this.teacherId,
    this.location,
    this.confirmed = true,
    this.dayOfWeek = 1,
    List<int>? time,
    this.firstHalf = false,
    this.secondHalf = false,
    this.oddWeek = false,
    this.evenWeek = false,
    this.customRepeat = false,
    List<int>? customRepeatWeeks,
    this.credit,
    this.online,
    this.type,
  }) : time = time ?? <int>[],
       customRepeatWeeks = customRepeatWeeks ?? <int>[];

  factory ScheduleSessionModel.empty() {
    return ScheduleSessionModel(name: '', teacher: '');
  }

  factory ScheduleSessionModel.fromCelechronJson(Map<String, dynamic> json) {
    return ScheduleSessionModel(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      teacher: json['teacher'] as String? ?? '',
      teacherId: json['teacherId'] as String?,
      location: json['location'] as String?,
      confirmed: json['confirmed'] as bool? ?? true,
      firstHalf: json['firstHalf'] as bool? ?? false,
      secondHalf: json['secondHalf'] as bool? ?? false,
      oddWeek: json['oddWeek'] as bool? ?? false,
      evenWeek: json['evenWeek'] as bool? ?? false,
      dayOfWeek: _intFromJson(json['day']) ?? 1,
      time: _intListFromJson(json['time']),
      customRepeat: json['customRepeat'] as bool? ?? false,
      customRepeatWeeks: _intListFromJson(json['customRepeatWeeks']),
      credit: _doubleFromJson(json['credit']),
      online: json['online'] as bool?,
      type: json['type'] as String?,
    );
  }

  static const String dayMap = '零一二三四五六日';

  String? get semesterId {
    final value = id;
    if (value == null || value.length < 12) {
      return null;
    }
    return value.substring(1, 12);
  }

  bool get showOnTimetable {
    return !customRepeat || customRepeatWeeks.length >= 3;
  }

  String get chineseTime {
    final weekText = oddWeek && evenWeek
        ? ''
        : oddWeek
        ? '单 - '
        : evenWeek
        ? '双 - '
        : '';
    final dayText = dayOfWeek >= 1 && dayOfWeek <= 7 ? dayMap[dayOfWeek] : '?';
    return '$weekText周$dayText第${time.join(', ')}节';
  }

  Map<String, dynamic> toCelechronJson() => {
    'id': id,
    'name': name,
    'teacher': teacher,
    'teacherId': teacherId,
    'confirmed': confirmed,
    'firstHalf': firstHalf,
    'secondHalf': secondHalf,
    'oddWeek': oddWeek,
    'evenWeek': evenWeek,
    'day': dayOfWeek,
    'time': time,
    'location': location,
    'customRepeat': customRepeat,
    'customRepeatWeeks': customRepeatWeeks,
    'credit': credit,
    'online': online,
    'type': type,
  };

  ScheduleSessionModel copyWith({
    String? id,
    String? name,
    String? teacher,
    String? teacherId,
    String? location,
    bool? confirmed,
    int? dayOfWeek,
    List<int>? time,
    bool? firstHalf,
    bool? secondHalf,
    bool? oddWeek,
    bool? evenWeek,
    bool? customRepeat,
    List<int>? customRepeatWeeks,
    double? credit,
    bool? online,
    String? type,
  }) {
    return ScheduleSessionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      teacher: teacher ?? this.teacher,
      teacherId: teacherId ?? this.teacherId,
      location: location ?? this.location,
      confirmed: confirmed ?? this.confirmed,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      time: time ?? List<int>.from(this.time),
      firstHalf: firstHalf ?? this.firstHalf,
      secondHalf: secondHalf ?? this.secondHalf,
      oddWeek: oddWeek ?? this.oddWeek,
      evenWeek: evenWeek ?? this.evenWeek,
      customRepeat: customRepeat ?? this.customRepeat,
      customRepeatWeeks:
          customRepeatWeeks ?? List<int>.from(this.customRepeatWeeks),
      credit: credit ?? this.credit,
      online: online ?? this.online,
      type: type ?? this.type,
    );
  }

  static int? _intFromJson(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static double? _doubleFromJson(Object? value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static List<int> _intListFromJson(Object? value) {
    if (value is! List) {
      return <int>[];
    }
    return value.map(_intFromJson).whereType<int>().toList(growable: true);
  }
}
