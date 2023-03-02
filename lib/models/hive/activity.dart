import 'package:hive/hive.dart';
import 'package:pingy/models/hive/activity_item.dart';

part 'activity.g.dart';

@HiveType(typeId: 3)
class Activity extends HiveObject {
  @HiveField(0)
  final String activityId;

  @HiveField(1)
  final List<ActivityItem> activityItems;

  @HiveField(2)
  final String score;

  @HiveField(3)
  final DateTime? activityDate;

  Activity(this.activityId, this.activityItems, this.score, this.activityDate);
}