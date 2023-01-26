import 'package:hive/hive.dart';

part 'activity.g.dart';

@HiveType(typeId: 2)
class Activity extends HiveObject {
  @HiveField(0)
  final String activityId;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String score;

  Activity(this.activityId, this.name, this.score);
}
