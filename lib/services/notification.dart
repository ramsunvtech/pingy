import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:pingy/config/notification_config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';

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
  
  // Goal expiry trigger notification (fires day after goal ends)
  static const int goalExpiryTriggerId = 107;

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
        // When goal expiry trigger fires, switch to weekday notifications
        if (response.id == goalExpiryTriggerId) {
          print('🔔 Goal expiry trigger fired - switching to weekday notifications');
          await rescheduleAll();
        }
      },
    );
  }

  // Get the device's local timezone name
  static Future<String> _getLocalTimeZone() async {
    try {
      // Get the system timezone name
      final now = DateTime.now();
      final timeZoneName = now.timeZoneName;
      
      // Try to find matching timezone in tz database
      try {
        tz.getLocation(timeZoneName);
        return timeZoneName;
      } catch (e) {
        // If exact name not found, try common mappings
        if (timeZoneName.contains('SGT') || timeZoneName.contains('Singapore')) {
          return 'Asia/Singapore';
        } else if (timeZoneName.contains('IST') || timeZoneName.contains('India')) {
          return 'Asia/Kolkata';
        } else if (timeZoneName.contains('PST') || timeZoneName.contains('PDT')) {
          return 'America/Los_Angeles';
        } else if (timeZoneName.contains('EST') || timeZoneName.contains('EDT')) {
          return 'America/New_York';
        }
        
        // Default to UTC if can't determine
        print('⚠️ Could not determine timezone, defaulting to UTC');
        return 'UTC';
      }
    } catch (e) {
      print('⚠️ Error getting timezone: $e');
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

  NotificationDetails getNotificationDetails() {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'pingy_channel', 
          'Pingy Notifications',
          channelDescription: 'Activity tracking reminders',
          importance: Importance.max,
          priority: Priority.high,
          autoCancel: false,
          enableVibration: true,
          playSound: true,
          icon: '@mipmap/ic_launcher', // Ensure this matches your app icon
        );
    const iOSChannelSpecifics = DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iOSChannelSpecifics,
    );

    return notificationDetails;
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
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      print('✅ Morning reminder scheduled for 10:00 AM (user local time)');
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
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      print('✅ Evening reminder scheduled for 8:00 PM (user local time)');
    } catch (e) {
      print('❌ Error scheduling evening reminder: $e');
    }
  }

  // ========== WEEKDAY-ONLY MOTIVATION REMINDERS (When NO goals) ==========
  
  static Future<void> scheduleWeekdayMotivationReminders() async {
    try {
      final rewardsBox = Hive.box('rewards');

      if (rewardsBox.isEmpty) {
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
        
        print('✅ Weekday motivation reminders scheduled (Mon-Fri at 11:30 AM, user local time)');
      } else {
        // Cancel all weekday motivation notifications if user has goals
        await cancelWeekdayMotivationReminders();
        print('❌ Weekday motivation reminders cancelled - user has goals');
      }
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
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Cancel all weekday motivation reminders
  static Future<void> cancelWeekdayMotivationReminders() async {
    await _flutterLocalNotificationsPlugin.cancel(motivationMondayId);
    await _flutterLocalNotificationsPlugin.cancel(motivationTuesdayId);
    await _flutterLocalNotificationsPlugin.cancel(motivationWednesdayId);
    await _flutterLocalNotificationsPlugin.cancel(motivationThursdayId);
    await _flutterLocalNotificationsPlugin.cancel(motivationFridayId);
  }

  // ========== SCHEDULE AUTO-SWITCH AFTER GOAL ENDS ==========
  
  /// Schedule a notification to fire the day after the last active goal ends
  /// This triggers the switch from daily to weekday notifications
  static Future<void> scheduleGoalExpiryTrigger(String endDateStr) async {
    try {
      // Parse the end date (format: dd/MM/yyyy)
      final endDate = DateFormat('dd/MM/yyyy').parse(endDateStr);
      
      // Schedule for 1 AM the day AFTER the goal ends
      final triggerDate = DateTime(
        endDate.year,
        endDate.month,
        endDate.day + 1, // Day after goal ends
        1, // 1 AM
        0,
      );
      
      final tzTriggerDate = tz.TZDateTime.from(triggerDate, tz.local);
      
      print('📅 Goal expiry trigger calculated for: ${tzTriggerDate.toString()}');
      
      // Only schedule if it's in the future
      if (tzTriggerDate.isAfter(tz.TZDateTime.now(tz.local))) {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          goalExpiryTriggerId,
          'Goal Completed! 🎉',
          'Time to set new goals and keep the momentum going!',
          tzTriggerDate,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'goal_expiry',
              'Goal Completion',
              channelDescription: 'Notifications when goals are completed',
              importance: Importance.high,
              priority: Priority.high,
              enableVibration: true,
              playSound: true,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
        
        print('✅ Goal expiry trigger scheduled for: $triggerDate');
      } else {
        print('⚠️ Goal expiry date is in the past, not scheduling');
      }
    } catch (e) {
      print('❌ Error scheduling goal expiry trigger: $e');
    }
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

    print('🕐 Next instance of ${hour}:${minute.toString().padLeft(2, '0')} is: ${scheduledDate.toString()}');
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
    print('🗑️ Notification $id cancelled');
  }

  // ========== MAIN RESCHEDULE METHOD ==========
  
  static Future<void> rescheduleAll() async {
    try {
      print('🔄 Starting notification reschedule...');
      
      final rewardsBox = Hive.box('rewards');
      
      if (rewardsBox.isEmpty) {
        // NO GOALS: Cancel daily reminders, schedule weekday motivation
        print('📊 No goals found - switching to weekday motivation mode');
        await cancel(dailyMorningReminderId);
        await cancel(dailyEveningReminderId);
        await cancel(goalExpiryTriggerId);
        await scheduleWeekdayMotivationReminders();
        print('✅ Rescheduled: Weekday motivation mode (no goals)');
      } else {
        // HAS GOALS: Cancel weekday motivation, schedule daily reminders
        print('📊 Goals found - switching to daily reminder mode');
        await cancelWeekdayMotivationReminders();
        await scheduleDailyMorningReminder();
        await scheduleDailyEveningReminder();
        
        // Find the latest goal end date and schedule auto-switch
        String? latestEndDate;
        DateTime? latestDate;
        
        for (var goal in rewardsBox.values) {
          if (goal.endDate != null && goal.endDate.isNotEmpty) {
            try {
              final endDate = DateFormat('dd/MM/yyyy').parse(goal.endDate);
              if (latestDate == null || endDate.isAfter(latestDate)) {
                latestDate = endDate;
                latestEndDate = goal.endDate;
              }
            } catch (e) {
              print('⚠️ Error parsing end date: $e');
            }
          }
        }
        
        // Schedule the auto-switch trigger
        if (latestEndDate != null) {
          await scheduleGoalExpiryTrigger(latestEndDate);
        }
        
        print('✅ Rescheduled: Daily reminder mode (has goals)');
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
      
      for (var notification in pending) {
        print('  ✓ ID ${notification.id}: ${notification.title}');
        if (notification.body != null) {
          print('    Body: ${notification.body}');
        }
      }
      
      print('📋 ===============================================');
    } catch (e) {
      print('❌ Error verifying notifications: $e');
    }
  }
}