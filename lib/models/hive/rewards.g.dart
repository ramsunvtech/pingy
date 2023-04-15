// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rewards.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RewardsModelAdapter extends TypeAdapter<RewardsModel> {
  @override
  final int typeId = 2;

  @override
  RewardsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RewardsModel(
      fields[0] as String,
      fields[1] as String,
      fields[2] as String,
      fields[3] as String,
      fields[4] as String,
      fields[5] as String,
      fields[6] as String?,
      fields[7] as String?,
      fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RewardsModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.startPeriod)
      ..writeByte(2)
      ..write(obj.endPeriod)
      ..writeByte(3)
      ..write(obj.firstPrice)
      ..writeByte(4)
      ..write(obj.secondPrice)
      ..writeByte(5)
      ..write(obj.thirdPrice)
      ..writeByte(6)
      ..write(obj.rewardPicture)
      ..writeByte(7)
      ..write(obj.rewardId)
      ..writeByte(8)
      ..write(obj.won);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RewardsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
