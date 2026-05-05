// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reward_wallet.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RewardWalletModelAdapter extends TypeAdapter<RewardWalletModel> {
  @override
  final int typeId = 3;

  @override
  RewardWalletModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RewardWalletModel(
      points: fields[0] as int,
      rewardedPomodoroIds: (fields[1] as List).cast<String>(),
      rewardedTaskIds: (fields[2] as List).cast<String>(),
      taskFocusSeconds: (fields[3] as Map).cast<String, int>(),
      foodInventory:
          (fields[4] as Map?)?.cast<String, int>() ?? <String, int>{},
    );
  }

  @override
  void write(BinaryWriter writer, RewardWalletModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.points)
      ..writeByte(1)
      ..write(obj.rewardedPomodoroIds)
      ..writeByte(2)
      ..write(obj.rewardedTaskIds)
      ..writeByte(3)
      ..write(obj.taskFocusSeconds)
      ..writeByte(4)
      ..write(obj.foodInventory);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RewardWalletModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
