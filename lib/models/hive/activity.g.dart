// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActivityAdapter extends TypeAdapter<Activity> {
  @override
  final int typeId = 3;

  @override
  Activity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Activity(
      fields[0] as String,
      (fields[1] as List).cast<ActivityItem>(),
      fields[2] as String,
      fields[3] as DateTime?,
      fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Activity obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.activityId)
      ..writeByte(1)
      ..write(obj.activityItems)
      ..writeByte(2)
      ..write(obj.score)
      ..writeByte(3)
      ..write(obj.activityDate)
      ..writeByte(4)
      ..write(obj.goalId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
