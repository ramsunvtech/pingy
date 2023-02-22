// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActivityType extends TypeAdapter<ActivityTypeModel> {
  @override
  final int typeId = 1;

  @override
  ActivityTypeModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ActivityTypeModel(
      fields[0] as String,
      fields[1] as String,
      fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ActivityTypeModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.activityTypeId)
      ..writeByte(1)
      ..write(obj.activityName)
      ..writeByte(2)
      ..write(obj.fullScore);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityType &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
