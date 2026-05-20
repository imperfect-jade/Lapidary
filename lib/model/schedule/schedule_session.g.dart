// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScheduleSessionModelAdapter extends TypeAdapter<ScheduleSessionModel> {
  @override
  final int typeId = 4;

  @override
  ScheduleSessionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScheduleSessionModel(
      id: fields[0] as String?,
      name: fields[1] as String,
      teacher: fields[2] as String,
      teacherId: fields[3] as String?,
      location: fields[4] as String?,
      confirmed: fields[5] as bool,
      dayOfWeek: fields[6] as int,
      time: (fields[7] as List?)?.cast<int>(),
      firstHalf: fields[8] as bool,
      secondHalf: fields[9] as bool,
      oddWeek: fields[10] as bool,
      evenWeek: fields[11] as bool,
      customRepeat: fields[12] as bool,
      customRepeatWeeks: (fields[13] as List?)?.cast<int>(),
      credit: fields[14] as double?,
      online: fields[15] as bool?,
      type: fields[16] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ScheduleSessionModel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.teacher)
      ..writeByte(3)
      ..write(obj.teacherId)
      ..writeByte(4)
      ..write(obj.location)
      ..writeByte(5)
      ..write(obj.confirmed)
      ..writeByte(6)
      ..write(obj.dayOfWeek)
      ..writeByte(7)
      ..write(obj.time)
      ..writeByte(8)
      ..write(obj.firstHalf)
      ..writeByte(9)
      ..write(obj.secondHalf)
      ..writeByte(10)
      ..write(obj.oddWeek)
      ..writeByte(11)
      ..write(obj.evenWeek)
      ..writeByte(12)
      ..write(obj.customRepeat)
      ..writeByte(13)
      ..write(obj.customRepeatWeeks)
      ..writeByte(14)
      ..write(obj.credit)
      ..writeByte(15)
      ..write(obj.online)
      ..writeByte(16)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleSessionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
