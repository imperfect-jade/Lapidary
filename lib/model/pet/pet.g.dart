// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PetModelAdapter extends TypeAdapter<PetModel> {
  @override
  final int typeId = 2;

  @override
  PetModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PetModel(
      id: fields[0] as String,
      species: fields[1] as String,
      name: fields[2] as String,
      level: fields[3] as int,
      exp: fields[4] as int,
      mood: fields[5] as int,
      hunger: fields[6] as int,
      energy: fields[7] as int,
      isSleeping: fields[8] as bool,
      lastInteractionAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PetModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.species)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.level)
      ..writeByte(4)
      ..write(obj.exp)
      ..writeByte(5)
      ..write(obj.mood)
      ..writeByte(6)
      ..write(obj.hunger)
      ..writeByte(7)
      ..write(obj.energy)
      ..writeByte(8)
      ..write(obj.isSleeping)
      ..writeByte(9)
      ..write(obj.lastInteractionAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PetModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
