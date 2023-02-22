import 'package:hive/hive.dart';
import 'package:pingy/models/hive/activity.dart';

class Boxes {
  static Box<Activity> getActivities() =>
      Hive.box<Activity>('activity');
}