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
import 'package:pingy/config/notification_config.dart';

// App.
import 'app.dart';

void main() async {
  // Initialize.
  WidgetsFlutterBinding.ensureInitialized();
  
  tz.initializeTimeZones();
  await NotificationService.initialize();

  // Request exact alarm permission for Android
  bool permissionGranted = await NotificationService.requestExactAlarmPermission();
  
  if (permissionGranted) {
    try {
      // Weekday Reminder (Monday to Friday only)
      await NotificationService().scheduleWeekdayNotification(
          id: NotificationConfig.weekdayReminderId,
          title: NotificationConfig.weekdayTitle,
          body: NotificationConfig.weekdayBody,
          hour: NotificationConfig.weekdayHour,
          minute: NotificationConfig.weekdayMinute);

      // Evening Reminder (Every day)
      await NotificationService().scheduleNotification(
          id: NotificationConfig.eveningReminderId,
          title: NotificationConfig.eveningTitle,
          body: NotificationConfig.eveningBody,
          scheduledNotificationDateTime:
              NotificationService().nextInstanceOfTenAM(
                NotificationConfig.eveningHour, 
                NotificationConfig.eveningMinute));
      
      // Schedule smart notifications (new goals, inactive users)
      await NotificationService.rescheduleAll();
      
      print('✅ Notifications scheduled successfully');
      print('   Weekday: ${NotificationConfig.weekdayHour}:${NotificationConfig.weekdayMinute.toString().padLeft(2, '0')}');
      print('   Evening: ${NotificationConfig.eveningHour}:${NotificationConfig.eveningMinute.toString().padLeft(2, '0')}');
    } catch (e) {
      print('❌ Failed to schedule notifications: $e');
    }
  } else {
    print('❌ Exact alarm permission not granted.');
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