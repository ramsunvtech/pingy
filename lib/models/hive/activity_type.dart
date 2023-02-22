import 'package:hive/hive.dart';

part 'activity_type.g.dart';

@HiveType(typeId: 1, adapterName: 'ActivityType')
class ActivityTypeModel extends HiveObject {
  @HiveField(0)
  final String activityTypeId;

  @HiveField(1)
  final String activityName;

  @HiveField(2)
  final String fullScore;

  ActivityTypeModel(this.activityTypeId, this.activityName, this.fullScore);
}