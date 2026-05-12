//番茄钟数据模型
import 'package:hive/hive.dart';

part 'pomodoro.g.dart';

@HiveType(typeId: 1)
class PomodoroModel extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String? taskId; // 关联的任务ID（可以为空，自由专注）
  @HiveField(2)
  String? taskTitle; // 任务标题快照（防止任务被删后显示问题）
  @HiveField(3)
  int durationMinutes; // 计划时长
  @HiveField(4)
  int actualSeconds; // 实际专注秒数
  @HiveField(5)
  DateTime startTime;
  @HiveField(6)
  DateTime? endTime;
  @HiveField(7)
  bool isCompleted; // 是否完整完成（没被打断）
  @HiveField(8)
  String type; // 'focus' 或 'break'

  PomodoroModel({
    required this.id,
    this.taskId,
    this.taskTitle,
    required this.durationMinutes,
    required this.actualSeconds,
    required this.startTime,
    this.endTime,
    required this.isCompleted,
    required this.type,
  });
}
