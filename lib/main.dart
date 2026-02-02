import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart'
    show PlatformDispatcher, kDebugMode, kIsWeb, kReleaseMode;

// Models.
import 'package:pingy/models/hive/activity_type.dart';
import 'package:pingy/models/hive/activity.dart';
import 'package:pingy/models/hive/rewards.dart';
import 'package:pingy/models/hive/activity_item.dart';
import 'package:pingy/models/hive/settings_model.dart';
import 'package:pingy/services/notification.dart';

// App.
import 'app.dart';

void main() async {
  // Initialize.
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
  await Hive.openBox<SettingsModel>('settings');

  if (!kIsWeb) {
    try {
      // Initialize notification service (this handles timezone setup)
      await NotificationService.initialize();
      print('✅ Notification service initialized');

      // Request exact alarm permission for Android
      bool permissionGranted = await NotificationService.requestExactAlarmPermission();

      if (permissionGranted) {
        print('✅ Exact alarm permission granted');
        
        // Schedule notifications based on goals
        await NotificationService.rescheduleAll();
        print('✅ Notifications scheduled successfully');
        
        // Verify what's scheduled (shows timezone info)
        await NotificationService.verifyScheduledNotifications();
      } else {
        print('❌ Exact alarm permission not granted');
      }
    } catch (e) {
      print('❌ Failed to initialize notifications: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      print('Pingy Error occurred: ${details.exception}');
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