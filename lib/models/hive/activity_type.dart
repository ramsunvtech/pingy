import 'package:hive/hive.dart';

part 'activity_type.g.dart';

@HiveType(typeId: 1)
class ActivityTypeModel extends HiveObject {
  @HiveField(0)
  final String activityTypeId;

  @HiveField(1)
  final String activityName;

  @HiveField(2)
  final String fullScore;

  @HiveField(3)
  final String? rank;

  ActivityTypeModel(this.activityTypeId, this.activityName, this.fullScore, this.rank);
}