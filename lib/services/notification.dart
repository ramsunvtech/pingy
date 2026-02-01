import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:pingy/config/notification_config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:pingy/models/hive/rewards.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Notification IDs
  static const int dailyMorningReminderId = 100;
  static const int dailyEveningReminderId = 101;
  
  // Weekday motivation notification IDs (Mon-Fri)
  static const int motivationMondayId = 102;
  static const int motivationTuesdayId = 103;
  static const int motivationWednesdayId = 104;
  static const int motivationThursdayId = 105;
  static const int motivationFridayId = 106;
  
  // Ongoing progress notification (Android only)
  static const int ongoingProgressId = 200;

  static Future<void> initialize() async {
    // IMPORTANT: Initialize timezone data first
    tz.initializeTimeZones();
    
    // Set local timezone - this is crucial for correct scheduling
    final String timeZoneName = await _getLocalTimeZone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
    
    print('🌍 Timezone set to: $timeZoneName');
    
    DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true);

    InitializationSettings initializationSettings = InitializationSettings(
      android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        print('🔔 Notification tapped: ID ${response.id}');
      },
    );
  }

  // Get the device's local timezone name
  static Future<String> _getLocalTimeZone() async {
    try {
      // Get timezone info from device
      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      
      print('🌍 Raw timezone offset: ${offset.inHours}h ${offset.inMinutes % 60}m');
      print('🌍 Raw timezone name: ${now.timeZoneName}');
      
      // Determine timezone based on offset (more reliable than name)
      final offsetHours = offset.inHours;
      final offsetMinutes = offset.inMinutes;
      
      String timeZoneName;
      
      // Map common offsets to reliable timezone names
      if (offsetHours == 8 && offsetMinutes == 480) {
        // Singapore, Malaysia, Philippines, Perth, Hong Kong
        timeZoneName = 'Asia/Singapore';
        print('🌍 Detected: Singapore/SEA timezone');
      } else if (offsetMinutes == 330) {
        // India (UTC+5:30)
        timeZoneName = 'Asia/Kolkata';
        print('🌍 Detected: India timezone');
      } else if (offsetHours == 0 || offsetHours == 1) {
        // UK (UTC or UTC+1 during BST)
        timeZoneName = 'Europe/London';
        print('🌍 Detected: UK timezone');
      } else if (offsetHours == -8 || offsetHours == -7) {
        // Pacific Time (US West)
        timeZoneName = 'America/Los_Angeles';
        print('🌍 Detected: US Pacific timezone');
      } else if (offsetHours == -5 || offsetHours == -4) {
        // Eastern Time (US East)
        timeZoneName = 'America/New_York';
        print('🌍 Detected: US Eastern timezone');
      } else if (offsetHours == 9) {
        // Japan, Korea
        timeZoneName = 'Asia/Tokyo';
        print('🌍 Detected: Japan/Korea timezone');
      } else if (offsetHours == 7) {
        // Thailand, Vietnam
        timeZoneName = 'Asia/Bangkok';
        print('🌍 Detected: Thailand/Vietnam timezone');
      } else {
        // Try to use system timezone name
        print('⚠️ Unusual offset, trying system timezone name');
        try {
          timeZoneName = now.timeZoneName;
          tz.getLocation(timeZoneName); // Test if it exists
        } catch (e) {
          print('⚠️ System timezone not found in database, defaulting to UTC');
          timeZoneName = 'UTC';
        }
      }
      
      print('🌍 Selected timezone: $timeZoneName');
      
      // Verify timezone exists in database
      try {
        tz.getLocation(timeZoneName);
        return timeZoneName;
      } catch (e) {
        print('❌ Timezone not found in database: $timeZoneName, using UTC');
        return 'UTC';
      }
    } catch (e) {
      print('❌ Error getting timezone: $e');
      return 'UTC';
    }
  }

  static Future<bool> requestExactAlarmPermission() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final bool? granted =
            await androidImplementation.canScheduleExactNotifications();

        if (granted == true) {
          return true;
        }

        final bool? requestResult =
            await androidImplementation.requestExactAlarmsPermission();
        return requestResult ?? false;
      }
    }
    return true;
  }

  // ========== CHECK IF ACTIVE GOAL EXISTS ==========
  
  static bool _hasActiveGoal() {
    try {
      final rewardsBox = Hive.box('rewards');
      
      if (rewardsBox.isEmpty) {
        print('📊 No goals in box');
        return false;
      }

      final today = DateTime.now();
      final normalizedToday = DateTime(today.year, today.month, today.day);

      // Check if any goal is currently active
      for (final goal in rewardsBox.values.cast<RewardsModel>()) {
        final start = _parseDate(goal.startPeriod);
        final end = _parseDate(goal.endPeriod);

        // Goal is active if today is between start and end (inclusive)
        if (!normalizedToday.isBefore(start) && !normalizedToday.isAfter(end)) {
          print('✅ Active goal found: ${goal.title}');
          return true;
        }
      }

      print('📊 No active goals (may have future or past goals)');
      return false;
    } catch (e) {
      print('❌ Error checking active goal: $e');
      return false;
    }
  }

  static DateTime _parseDate(String date) {
    final parts = date.split('/');
    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);
    return DateTime(year, month, day);
  }

  // ========== DAILY REMINDERS (When goals exist) ==========
  
  static Future<void> scheduleDailyMorningReminder() async {
    try {
      final scheduledTime = _nextInstanceOfTime(
        NotificationConfig.dailyMorningHour, 
        NotificationConfig.dailyMorningMinute
      );
      
      print('📅 Scheduling morning reminder for: ${scheduledTime.toString()}');
      
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        dailyMorningReminderId,
        'Time to update your progress! 🌅',
        'Don\'t forget to log today\'s activities 📝',
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_morning_reminder',
            'Daily Morning Reminders',
            channelDescription: 'Morning activity reminders',
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      
      print('✅ Morning reminder scheduled for 10:00 AM daily');
    } catch (e) {
      print('❌ Error scheduling morning reminder: $e');
    }
  }

  static Future<void> scheduleDailyEveningReminder() async {
    try {
      final scheduledTime = _nextInstanceOfTime(
        NotificationConfig.dailyEveningHour, 
        NotificationConfig.dailyEveningMinute
      );
      
      print('📅 Scheduling evening reminder for: ${scheduledTime.toString()}');
      
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        dailyEveningReminderId,
        'Evening Check-in! 🌙',
        'How did your day go? Update your activities!',
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_evening_reminder',
            'Daily Evening Reminders',
            channelDescription: 'Evening activity reminders',
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      
      print('✅ Evening reminder scheduled for 8:00 PM daily');
    } catch (e) {
      print('❌ Error scheduling evening reminder: $e');
    }
  }

  // ========== WEEKDAY-ONLY MOTIVATION REMINDERS (When NO goals) ==========
  
  static Future<void> scheduleWeekdayMotivationReminders() async {
    try {
      // Get random motivational message
      final messages = [
        {
          'title': 'Ready to start your journey? 🎯',
          'body': 'Set your first goal and start tracking your progress!'
        },
        {
          'title': 'Your success story starts here! ⭐',
          'body': 'Create your first goal and begin your transformation!'
        },
        {
          'title': 'Today is the perfect day! 💪',
          'body': 'Don\'t wait! Start setting goals and achieving them!'
        },
        {
          'title': 'Great things start with a goal! 🚀',
          'body': 'Take the first step - add your goal now!'
        },
      ];

      final random = messages[DateTime.now().millisecond % messages.length];
      
      // Schedule for MONDAY at 11:30 AM
      await _scheduleWeekdayNotification(
        id: motivationMondayId,
        weekday: DateTime.monday,
        title: random['title']!,
        body: random['body']!,
      );
      
      // Schedule for TUESDAY at 11:30 AM
      await _scheduleWeekdayNotification(
        id: motivationTuesdayId,
        weekday: DateTime.tuesday,
        title: random['title']!,
        body: random['body']!,
      );
      
      // Schedule for WEDNESDAY at 11:30 AM
      await _scheduleWeekdayNotification(
        id: motivationWednesdayId,
        weekday: DateTime.wednesday,
        title: random['title']!,
        body: random['body']!,
      );
      
      // Schedule for THURSDAY at 11:30 AM
      await _scheduleWeekdayNotification(
        id: motivationThursdayId,
        weekday: DateTime.thursday,
        title: random['title']!,
        body: random['body']!,
      );
      
      // Schedule for FRIDAY at 11:30 AM
      await _scheduleWeekdayNotification(
        id: motivationFridayId,
        weekday: DateTime.friday,
        title: random['title']!,
        body: random['body']!,
      );
      
      print('✅ Weekday motivation reminders scheduled (Mon-Fri at 11:30 AM)');
    } catch (e) {
      print('❌ Error scheduling weekday motivation reminders: $e');
    }
  }

  // Helper: Schedule a single weekday notification
  static Future<void> _scheduleWeekdayNotification({
    required int id,
    required int weekday,
    required String title,
    required String body,
  }) async {
    final scheduledDate = _nextInstanceOfWeekday(
      weekday: weekday,
      hour: NotificationConfig.motivationHour,
      minute: NotificationConfig.motivationMinute,
    );

    print('📅 Scheduling weekday notification (ID: $id) for: ${scheduledDate.toString()}');

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'motivation',
          'Motivation',
          channelDescription: 'Motivational reminders for new users',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  // Cancel all weekday motivation reminders
  static Future<void> cancelWeekdayMotivationReminders() async {
    await _flutterLocalNotificationsPlugin.cancel(motivationMondayId);
    await _flutterLocalNotificationsPlugin.cancel(motivationTuesdayId);
    await _flutterLocalNotificationsPlugin.cancel(motivationWednesdayId);
    await _flutterLocalNotificationsPlugin.cancel(motivationThursdayId);
    await _flutterLocalNotificationsPlugin.cancel(motivationFridayId);
    print('🗑️ Weekday motivation reminders cancelled');
  }

  // ========== ONGOING NOTIFICATION (Android Only) ==========
  
  /// Show persistent notification when goal is active
  /// This stays in notification area until dismissed or goal ends
  static Future<void> showOngoingProgress({
    required String todayScore,
    required String totalScore,
    required String goalTitle,
  }) async {
    if (!Platform.isAndroid) return;

    try {
      // Build notification details without const (due to string interpolation)
      final androidDetails = AndroidNotificationDetails(
        'ongoing_progress',
        'Ongoing Progress',
        channelDescription: 'Shows your current progress',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true, // Makes it persistent
        autoCancel: false, // Won't dismiss when tapped
        showWhen: false,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(
          'Today: $todayScore% | Total: $totalScore%',
          contentTitle: '📊 $goalTitle',
          summaryText: 'Keep going!',
        ),
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        ongoingProgressId,
        '📊 $goalTitle',
        'Today: $todayScore% | Total: $totalScore%',
        notificationDetails,
      );

      print('✅ Ongoing progress notification shown');
    } catch (e) {
      print('❌ Error showing ongoing notification: $e');
    }
  }

  /// Update the ongoing notification with new scores
  static Future<void> updateOngoingProgress({
    required String todayScore,
    required String totalScore,
    required String goalTitle,
  }) async {
    // Just call showOngoingProgress again - it will update the existing notification
    await showOngoingProgress(
      todayScore: todayScore,
      totalScore: totalScore,
      goalTitle: goalTitle,
    );
  }

  /// Hide the ongoing notification
  static Future<void> hideOngoingProgress() async {
    await _flutterLocalNotificationsPlugin.cancel(ongoingProgressId);
    print('🗑️ Ongoing progress notification hidden');
  }

  // ========== HELPER METHODS ==========

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  static tz.TZDateTime _nextInstanceOfWeekday({
    required int weekday,
    required int hour,
    required int minute,
  }) {
    var scheduledDate = _nextInstanceOfTime(hour, minute);

    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  static Future<void> cancelAll() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    print('🗑️ All notifications cancelled');
  }

  static Future<void> cancel(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  // ========== MAIN RESCHEDULE METHOD ==========
  
  static Future<void> rescheduleAll() async {
    try {
      print('🔄 Starting notification reschedule...');
      
      // Cancel everything first to start fresh
      await cancelAll();
      
      final hasActiveGoal = _hasActiveGoal();
      
      if (hasActiveGoal) {
        // HAS ACTIVE GOAL: Schedule daily reminders
        print('📊 Active goal detected - scheduling daily reminders');
        await scheduleDailyMorningReminder();
        await scheduleDailyEveningReminder();
        print('✅ Rescheduled: Daily reminder mode (10 AM & 8 PM)');
      } else {
        // NO ACTIVE GOAL: Schedule weekday motivation
        print('📊 No active goal - scheduling weekday motivation');
        await scheduleWeekdayMotivationReminders();
        print('✅ Rescheduled: Weekday motivation mode (Mon-Fri 11:30 AM)');
      }
      
      // Verify what's scheduled
      await verifyScheduledNotifications();
    } catch (e) {
      print('❌ Error rescheduling notifications: $e');
    }
  }

  // Verify pending notifications (for debugging)
  static Future<void> verifyScheduledNotifications() async {
    try {
      final pending = await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      final now = tz.TZDateTime.now(tz.local);
      
      print('📋 ========== SCHEDULED NOTIFICATIONS ==========');
      print('📋 Current time: ${now.toString()}');
      print('📋 Timezone: ${now.timeZoneName}');
      print('📋 Total pending: ${pending.length}');
      
      if (pending.isEmpty) {
        print('  ⚠️ No notifications scheduled!');
      } else {
        for (var notification in pending) {
          print('  ✓ ID ${notification.id}: ${notification.title}');
          if (notification.body != null) {
            print('    Body: ${notification.body}');
          }
        }
      }
      
      print('📋 ===============================================');
    } catch (e) {
      print('❌ Error verifying notifications: $e');
    }
  }
}