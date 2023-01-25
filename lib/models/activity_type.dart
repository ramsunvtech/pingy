import 'package:hive/hive.dart';

part 'activity_type.g.dart';

@HiveType(typeId: 0)
class ActivityTypeModel extends HiveObject {
  @HiveField(0)
  final String activityName;

  @HiveField(1)
  final String mark;

  ActivityTypeModel(this.activityName, this.mark);
}