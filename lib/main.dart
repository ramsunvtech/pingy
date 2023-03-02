import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:pingy/models/hive/activity_item.dart';
import 'package:pingy/models/hive/activity_type.dart';
import 'package:pingy/models/hive/activity.dart';
import 'package:pingy/models/hive/rewards.dart';

// Screen Imports.
import 'screens/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var path = "/assets/db";
  if (!kIsWeb) {
    var appDocDir = await getApplicationDocumentsDirectory();
    path = appDocDir.path;
  }

  // Initialize hive.
  await Hive.initFlutter();

  // Register Adapters.
  Hive
    ..init(path)
    ..registerAdapter(ActivityAdapter())
    ..registerAdapter(ActivityTypeModelAdapter())
    ..registerAdapter(ActivityItemAdapter())
    ..registerAdapter(RewardsModelAdapter());

  // Open Activity Type, Rewards and Activity Box.
  final activityTypeBox = await Hive.openBox('activity_type');
  var rewardBox = await Hive.openBox('rewards');
  var activityBox = await Hive.openBox('activity');

  // Add Today Activity if not exist.
  var today = DateTime.now();
  var activityId = 'activity_${today.year}${today.month}${today.day}';
  bool canCreateNewActivity = true;

  if (rewardBox.isEmpty || activityTypeBox.isEmpty) {
    canCreateNewActivity = false;
  }

  if (activityBox.containsKey(activityId)) {
    // print('Log: Today Activity is exist');
    Activity todayActivity = activityBox.get(activityId);
    if (todayActivity.activityItems.isNotEmpty) {
      // print('Log: Today Activity Type is not empty');
      canCreateNewActivity = false;
    }
  }

  if (canCreateNewActivity) {
    final activityTypeKeys = await activityTypeBox.keys;
    final List<ActivityItem> activityItems = [];
    for (var activityTypeKey in activityTypeKeys) {
      ActivityItem newActivityItem = ActivityItem(activityTypeKey, '');
      activityItems.add(newActivityItem);
    }
    Activity newActivity = Activity(activityId, activityItems, '', DateTime.now());
    activityBox.put(activityId, newActivity);
  }

  runApp(
    PingyApp(),
  );
}

class PingyApp extends StatefulWidget {
  @override
  _PingyAppState createState() => _PingyAppState();
}

class _PingyAppState extends State<PingyApp> {
  @override
  void dispose() {
    // Closes all Hive boxes
    Hive.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xff6750a4)),
      home: HomeScreen(),
    );
  }
}
