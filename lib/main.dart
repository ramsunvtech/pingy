import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/foundation.dart'
    show PlatformDispatcher, kDebugMode, kIsWeb, kReleaseMode;

// Models.
import 'package:pingy/models/hive/activity_type.dart';
import 'package:pingy/models/hive/activity.dart';
import 'package:pingy/models/hive/rewards.dart';
import 'package:pingy/models/hive/activity_item.dart';
import 'package:pingy/services/notification.dart';

// App.
import 'app.dart';

void main() async {
  // Initialize.
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  tz.initializeTimeZones();

  // Request exact alarm permission for Android
  bool permissionGranted = await NotificationService.requestExactAlarmPermission();
  
  if (permissionGranted) {
    try {
      // Morning Reminder
      await NotificationService().scheduleNotification(
          id: 1,
          title: 'Steppy Reminder',
          body: 'Good Morning, Time to update your activities :)',
          scheduledNotificationDateTime:
              NotificationService().nextInstanceOfTenAM(10, 00));

      // Evening Reminder
      await NotificationService().scheduleNotification(
          id: 2,
          title: 'Steppy Reminder',
          body: 'Good Evening, Time to update your activities :)',
          scheduledNotificationDateTime:
              NotificationService().nextInstanceOfTenAM(20, 00));
      
      print('Notifications scheduled successfully');
    } catch (e) {
      print('Failed to schedule notifications: $e');
    }
  } else {
    print('Exact alarm permission not granted. Notifications will not be scheduled.');
  }

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

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      print('Steppy Error occurred: ${details.exception}');
    }
    if (kReleaseMode) exit(1);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    return true;
  };

  runApp(
    PingyApp(),
  );
}
