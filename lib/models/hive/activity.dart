import 'package:hive/hive.dart';

part 'activity.g.dart';

@HiveType(typeId: 3, adapterName: 'Activity')
class Activity extends HiveObject {
  @HiveField(0)
  final String activityId;

  @HiveField(1)
  late List<ActivityItem> activityItems;

  @HiveField(2)
  final String score;

  Activity(this.activityId, this.activityItems, this.score);
}

@HiveType(typeId: 4, adapterName: 'ActivityItem')
class ActivityItem extends HiveObject {
  @HiveField(0)
  late String activityItemId;

  @HiveField(1)
  late String score;
}
