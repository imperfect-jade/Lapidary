// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskModelAdapter extends TypeAdapter<TaskModel> {
  @override
  final int typeId = 0;

  @override
  TaskModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskModel(
      id: fields[0] as String,
      title: fields[1] as String,
      deadline: fields[4] as DateTime,
      isCompleted: fields[2] as bool,
      createdAt: fields[3] as DateTime?,
      priority: fields[5] as int,
      description: fields[6] as String?,
      taskType: fields[7] == null ? 'day' : fields[7] as String,
      focusTargetPeriod: fields[8] == null ? 'daily' : fields[8] as String,
      focusTargetMinutes: fields[9] == null ? 0 : fields[9] as int,
      overdueMoodPenaltyApplied:
          fields[10] == null ? false : fields[10] as bool,
      completedAt: fields[11] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TaskModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.isCompleted)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.deadline)
      ..writeByte(5)
      ..write(obj.priority)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.taskType)
      ..writeByte(8)
      ..write(obj.focusTargetPeriod)
      ..writeByte(9)
      ..write(obj.focusTargetMinutes)
      ..writeByte(10)
      ..write(obj.overdueMoodPenaltyApplied)
      ..writeByte(11)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
