import 'package:hive/hive.dart';

part 'activity.g.dart';

@HiveType(typeId: 0)
class Activity extends HiveObject {

  @HiveField(0)
  late String activityId;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late int score;
}