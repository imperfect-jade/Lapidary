import 'package:hive/hive.dart';

part 'task.g.dart';

class TaskType {
  static const String day = 'day';
  static const String week = 'week';
  static const String month = 'month';

  static const List<String> values = [day, week, month];

  static String labelOf(String value) {
    switch (value) {
      case week:
        return '周任务';
      case month:
        return '月任务';
      case day:
      default:
        return '日任务';
    }
  }
}

class FocusTargetPeriod {
  static const String daily = 'daily';
  static const String weekly = 'weekly';
  static const String monthly = 'monthly';

  static const List<String> values = [daily, weekly, monthly];

  static String labelOf(String value) {
    switch (value) {
      case weekly:
        return '每周';
      case monthly:
        return '每月';
      case daily:
      default:
        return '每天';
    }
  }
}

@HiveType(typeId: 0)
class TaskModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  bool isCompleted;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime deadline;

  @HiveField(5)
  int priority;

  @HiveField(6)
  String? description;

  @HiveField(7, defaultValue: TaskType.day)
  String taskType;

  @HiveField(8, defaultValue: FocusTargetPeriod.daily)
  String focusTargetPeriod;

  @HiveField(9, defaultValue: 0)
  int focusTargetMinutes;

  @HiveField(10, defaultValue: false)
  bool overdueMoodPenaltyApplied;

  TaskModel({
    required this.id,
    required this.title,
    required this.deadline,
    this.isCompleted = false,
    DateTime? createdAt,
    this.priority = 3,
    this.description,
    this.taskType = TaskType.day,
    this.focusTargetPeriod = FocusTargetPeriod.daily,
    this.focusTargetMinutes = 0,
    this.overdueMoodPenaltyApplied = false,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get hasFocusTarget {
    return taskType != TaskType.day && focusTargetMinutes > 0;
  }
}
