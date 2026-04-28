//创建待办任务数据模型
import 'package:hive/hive.dart';
part 'task.g.dart';

@HiveType(typeId: 0)
class TaskModel extends HiveObject
{
  @HiveField(0)
  String id; //任务id
  @HiveField(1)
  String title; //任务标题
  @HiveField(2)
  bool isCompleted; //是否完成
  @HiveField(3)
  DateTime createdAt; //创建时间
  @HiveField(4)
  DateTime deadline; //预期完成时间
  @HiveField(5)
  int priority; //优先级
  @HiveField(6)
  String? description; //任务描述

  //构造函数
  TaskModel({
    required this.id,
    required this.title,
    required this.deadline,
    this.isCompleted = false,
    DateTime? createdAt,
    this.priority = 3,
    this.description,
  }) : createdAt = createdAt ?? DateTime.now();
}