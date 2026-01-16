import 'dart:io';
import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:pingy/config/notification_config.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Notification IDs
  static const int dailyReminderId = 100;
  static const int motivationReminderId = 101;
  static const int inactiveReminderId = 102;

  DateTime nextInstanceOfTenAM(int hour, int minutes) {
    final DateTime now = DateTime.now();
    DateTime scheduledDate = DateTime(now.year, now.month, now.day, hour, minutes);
    
    // If time has passed today, start checking from tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  // Get next weekday instance (Monday to Friday only)
  DateTime nextWeekdayInstance(int hour, int minutes) {
    final DateTime now = DateTime.now();
    DateTime scheduledDate = DateTime(now.year, now.month, now.day, hour, minutes);
    
    // If time has passed today, start checking from tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    // Skip to next weekday if it falls on weekend
    while (scheduledDate.weekday == DateTime.saturday || 
           scheduledDate.weekday == DateTime.sunday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    
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
        // When weekday notification is received, reschedule next one
        if (response.id == NotificationConfig.weekdayReminderId) {
          final service = NotificationService();
          await service.scheduleWeekdayNotification(
            id: NotificationConfig.weekdayReminderId,
            title: NotificationConfig.weekdayTitle,
            body: NotificationConfig.weekdayBody,
            hour: NotificationConfig.weekdayHour,
            minute: NotificationConfig.weekdayMinute,
          );
        }
      },
    );
  }

  // Request exact alarm permission for Android 12+
  static Future<bool> requestExactAlarmPermission() async {
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
        AndroidNotificationDetails('my-channel', 'Steppy Notifications',
            importance: Importance.max,
            priority: Priority.high,
            autoCancel: false,
            enableVibration: true,
            playSound: true);
    const iOSChannelSpecifics = DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iOSChannelSpecifics,
    );

    return notificationDetails;
  }

  void display() async {
    try {
      Random random = Random();
      int id = random.nextInt(1000);

      await _flutterLocalNotificationsPlugin.show(
          id, 'your title', 'your body', getNotificationDetails());
    } catch (e) {
      print('Error>>>$e');
    }
  }

  Future<bool> scheduleNotification({
    required int id,
    String? title,
    String? body,
    String? payload,
    required DateTime scheduledNotificationDateTime,
  }) async {
    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(
          scheduledNotificationDateTime,
          tz.local,
        ),
        getNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      return true;
    } catch (e) {
      print('Error scheduling notification: $e');
      return false;
    }
  }

  // Schedule weekday-only notification (Monday to Friday)
  Future<bool> scheduleWeekdayNotification({
    required int id,
    String? title,
    String? body,
    required int hour,
    required int minute,
  }) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
      
      final DateTime nextNotification = nextWeekdayInstance(hour, minute);
      
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(nextNotification, tz.local),
        getNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      
      print('Weekday notification scheduled for: $nextNotification');
      return true;
    } catch (e) {
      print('Error scheduling weekday notification: $e');
      return false;
    }
  }

  // ========== NEW METHODS ==========

  // Schedule daily reminder at specific time (repeats daily)
  static Future<void> scheduleDailyReminder({
    int? hour,
    int? minute,
    String? title,
    String? body,
  }) async {
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      NotificationConfig.dailyReminderId,
      title ?? 'Time to update your progress!',
      body ?? 'Don\'t forget to log today\'s activities 📝',
      _nextInstanceOfTime(
        hour ?? NotificationConfig.dailyHour, 
        minute ?? NotificationConfig.dailyMinute
      ),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminders',
          channelDescription: 'Daily activity reminders',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Schedule motivation for users without goals
  static Future<void> scheduleMotivationReminder() async {
    try {
      final rewardBox = Hive.box('rewards');

      if (rewardBox.isEmpty) {
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

        await _flutterLocalNotificationsPlugin.zonedSchedule(
          NotificationConfig.motivationReminderId,
          random['title'],
          random['body'],
          _nextInstanceOfTime(
            NotificationConfig.motivationHour, 
            NotificationConfig.motivationMinute
          ),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'motivation',
              'Motivation',
              channelDescription: 'Motivational reminders for new users',
              importance: Importance.high,
              priority: Priority.high,
              enableVibration: true,
              playSound: true,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } else {
        await _flutterLocalNotificationsPlugin.cancel(NotificationConfig.motivationReminderId);
      }
    } catch (e) {
      print('Error scheduling motivation reminder: $e');
    }
  }

  // Schedule reminder for users who haven't logged activity today
  static Future<void> scheduleInactiveUserReminder() async {
    try {
      final activityBox = Hive.box('activity');
      final rewardBox = Hive.box('rewards');
      
      if (rewardBox.isEmpty) return;

      final today = DateTime.now();
      final todayId = 'activity_${today.year}${today.month}${today.day}';
      final hasActivity = activityBox.containsKey(todayId);
      
      if (!hasActivity) {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          NotificationConfig.inactiveReminderId,
          'Don\'t break your streak! 🔥',
          'You haven\'t updated your activities today. Keep going!',
          _nextInstanceOfTime(
            NotificationConfig.inactiveHour,
            NotificationConfig.inactiveMinute
          ),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'inactive_reminder',
              'Activity Reminders',
              channelDescription: 'Reminders for users who haven\'t logged activities',
              importance: Importance.high,
              priority: Priority.high,
              enableVibration: true,
              playSound: true,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } else {
        await _flutterLocalNotificationsPlugin.cancel(NotificationConfig.inactiveReminderId);
      }
    } catch (e) {
      print('Error scheduling inactive reminder: $e');
    }
  }

  // Helper to get next instance of specific time
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

    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // Cancel all notifications
  static Future<void> cancelAll() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  // Cancel specific notification
  static Future<void> cancel(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  // Reschedule all notifications (call when app opens/resumes)
  static Future<void> rescheduleAll() async {
    try {
      await scheduleDailyReminder(); // Uses config values
      await scheduleMotivationReminder(); // Uses config values
      await scheduleInactiveUserReminder(); // Uses config values
    } catch (e) {
      print('Error rescheduling notifications: $e');
    }
  }
}