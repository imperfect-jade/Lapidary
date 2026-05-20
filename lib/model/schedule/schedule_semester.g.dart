// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_semester.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScheduleSemesterModelAdapter extends TypeAdapter<ScheduleSemesterModel> {
  @override
  final int typeId = 5;

  @override
  ScheduleSemesterModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScheduleSemesterModel(
      id: fields[0] as String,
      name: fields[1] as String,
      sessions: (fields[2] as List?)?.cast<ScheduleSessionModel>(),
      sessionToTimeMinutes: (fields[3] as List?)
          ?.map((dynamic e) => (e as List).cast<int>())
          ?.toList(),
      dayOfWeekToDays: (fields[4] as List?)
          ?.map((dynamic e) => (e as List)
              .map((dynamic e) => (e as List)
                  .map((dynamic e) => (e as List).cast<DateTime>())
                  .toList())
              .toList())
          ?.toList(),
      holidays: (fields[5] as Map?)?.cast<DateTime, String>(),
      exchanges: (fields[6] as Map?)?.cast<DateTime, DateTime>(),
      lastSyncedAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ScheduleSemesterModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.sessions)
      ..writeByte(3)
      ..write(obj.sessionToTimeMinutes)
      ..writeByte(4)
      ..write(obj.dayOfWeekToDays)
      ..writeByte(5)
      ..write(obj.holidays)
      ..writeByte(6)
      ..write(obj.exchanges)
      ..writeByte(7)
      ..write(obj.lastSyncedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleSemesterModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
