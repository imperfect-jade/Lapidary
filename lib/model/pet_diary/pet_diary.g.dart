// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet_diary.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PetDiaryModelAdapter extends TypeAdapter<PetDiaryModel> {
  @override
  final int typeId = 6;

  @override
  PetDiaryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PetDiaryModel(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      completedTaskCount: fields[2] as int,
      focusMinutes: fields[3] as int,
      focusSessionCount: fields[4] as int,
      lateNightTaskCount: fields[5] as int,
      diaryText: fields[6] as String,
      generatedAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PetDiaryModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.completedTaskCount)
      ..writeByte(3)
      ..write(obj.focusMinutes)
      ..writeByte(4)
      ..write(obj.focusSessionCount)
      ..writeByte(5)
      ..write(obj.lateNightTaskCount)
      ..writeByte(6)
      ..write(obj.diaryText)
      ..writeByte(7)
      ..write(obj.generatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PetDiaryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
