import 'package:hive/hive.dart';

part 'activity_item.g.dart';

@HiveType(typeId: 4)
class ActivityItem extends HiveObject {
  @HiveField(0)
  late String activityItemId;

  @HiveField(1)
  late String score;

  ActivityItem(this.activityItemId, this.score);
}
