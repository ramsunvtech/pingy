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

  tz.initializeTimeZones();

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

  // ========== INITIALIZE NOTIFICATIONS ==========
  if (!kIsWeb) {
    await NotificationService.initialize();

    // Request exact alarm permission for Android
    bool permissionGranted =
        await NotificationService.requestExactAlarmPermission();

    if (permissionGranted) {
      try {
        // Use the new unified rescheduleAll method
        // This automatically schedules the right notifications based on whether goals exist
        await NotificationService.rescheduleAll();

        print('✅ Notifications scheduled successfully');
        
        // Debug: Show what's scheduled
        await NotificationService.verifyScheduledNotifications();
      } catch (e) {
        print('❌ Failed to schedule notifications: $e');
      }
    } else {
      print('❌ Exact alarm permission not granted.');
    }
  }

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