import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:pingy/models/hive/activity_type.dart';
import 'package:pingy/models/hive/activity.dart';
import 'package:pingy/models/hive/rewards.dart';
import 'package:pingy/models/hive/activity_item.dart';

import 'app.dart';

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
  await Hive.openBox('activity_type');
  await Hive.openBox('rewards');
  await Hive.openBox('activity');

  runApp(
    PingyApp(),
  );
}
