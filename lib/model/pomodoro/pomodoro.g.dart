// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pomodoro.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PomodoroModelAdapter extends TypeAdapter<PomodoroModel> {
  @override
  final int typeId = 1;

  @override
  PomodoroModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PomodoroModel(
      id: fields[0] as String,
      taskId: fields[1] as String?,
      taskTitle: fields[2] as String?,
      durationMinutes: fields[3] as int,
      actualSeconds: fields[4] as int,
      startTime: fields[5] as DateTime,
      endTime: fields[6] as DateTime?,
      isCompleted: fields[7] as bool,
      type: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PomodoroModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.taskId)
      ..writeByte(2)
      ..write(obj.taskTitle)
      ..writeByte(3)
      ..write(obj.durationMinutes)
      ..writeByte(4)
      ..write(obj.actualSeconds)
      ..writeByte(5)
      ..write(obj.startTime)
      ..writeByte(6)
      ..write(obj.endTime)
      ..writeByte(7)
      ..write(obj.isCompleted)
      ..writeByte(8)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PomodoroModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
