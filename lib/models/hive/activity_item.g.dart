// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActivityItemAdapter extends TypeAdapter<ActivityItem> {
  @override
  final int typeId = 4;

  @override
  ActivityItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ActivityItem(
      fields[0] as String,
      fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ActivityItem obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.activityItemId)
      ..writeByte(1)
      ..write(obj.score);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
