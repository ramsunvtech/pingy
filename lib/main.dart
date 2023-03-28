import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/foundation.dart'
    show PlatformDispatcher, kIsWeb, kReleaseMode;

import 'package:pingy/models/hive/activity_type.dart';
import 'package:pingy/models/hive/activity.dart';
import 'package:pingy/models/hive/rewards.dart';
import 'package:pingy/models/hive/activity_item.dart';
import 'package:pingy/services/notification.dart';

import 'app.dart';

void main() async {
  // Initialize.
  WidgetsFlutterBinding.ensureInitialized();
  NotificationService.initialize();
  tz.initializeTimeZones();

  // Morning Reminder
  NotificationService().scheduleNotification(
      title: 'Pingy Reminder',
      body: 'Good Morning, Time to update your activities :)',
      scheduledNotificationDateTime:
      NotificationService().nextInstanceOfTenAM(08, 00));

  // Evening Reminder
  NotificationService().scheduleNotification(
      title: 'Pingy Reminder',
      body: 'Good Evening, Time to update your activities :)',
      scheduledNotificationDateTime:
          NotificationService().nextInstanceOfTenAM(20, 00));

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

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kReleaseMode) exit(1);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    return true;
  };

  runApp(
    PingyApp(),
  );
}
