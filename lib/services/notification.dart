import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:pingy/config/notification_config.dart';
import 'package:pingy/models/hive/rewards.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Notification IDs
  static const int dailyMorningReminderId = 100;
  static const int dailyEveningReminderId = 101;

  static const int motivationMondayId = 102;
  static const int motivationTuesdayId = 103;
  static const int motivationWednesdayId = 104;
  static const int motivationThursdayId = 105;
  static const int motivationFridayId = 106;

  static const int ongoingProgressId = 200;

  // ================= INIT =================

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    final String timeZoneName = await _getLocalTimeZone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    final initializationSettings = InitializationSettings(
      android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        print('🔔 Notification tapped: ${response.id}');
      },
    );
  }

  // ================= TIMEZONE =================

  static Future<String> _getLocalTimeZone() async {
    try {
      final offset = DateTime.now().timeZoneOffset;

      if (offset.inMinutes == 480) return 'Asia/Singapore';
      if (offset.inMinutes == 330) return 'Asia/Kolkata';
      if (offset.inHours == 0 || offset.inHours == 1) return 'Europe/London';
      if (offset.inHours == -8 || offset.inHours == -7) {
        return 'America/Los_Angeles';
      }
      if (offset.inHours == -5 || offset.inHours == -4) {
        return 'America/New_York';
      }
      if (offset.inHours == 9) return 'Asia/Tokyo';
      if (offset.inHours == 7) return 'Asia/Bangkok';

      return 'UTC';
    } catch (_) {
      return 'UTC';
    }
  }

  // ================= PERMISSIONS =================

  static Future<bool> requestExactAlarmPermission() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final android =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (android == null) return false;

      final granted = await android.canScheduleExactNotifications();
      if (granted == true) return true;

      return await android.requestExactAlarmsPermission() ?? false;
    }
    return true;
  }

  // ================= GOAL CHECK =================

  static bool _hasActiveGoal() {
    try {
      final box = Hive.box('rewards');
      if (box.isEmpty) return false;

      final today = DateTime.now();
      final normalizedToday =
          DateTime(today.year, today.month, today.day);

      for (final goal in box.values.cast<RewardsModel>()) {
        final start = _parseDate(goal.startPeriod);
        final end = _parseDate(goal.endPeriod);

        if (!normalizedToday.isBefore(start) &&
            !normalizedToday.isAfter(end)) {
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static DateTime _parseDate(String date) {
    final p = date.split('/');
    return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
  }

  // ================= DAILY REMINDERS =================

  static Future<void> scheduleDailyMorningReminder() async {
    final scheduledTime = _nextInstanceOfTime(
      NotificationConfig.dailyMorningHour,
      NotificationConfig.dailyMorningMinute,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      dailyMorningReminderId,
      'Time to update your progress! 🌅',
      'Don\'t forget to log today\'s activities 📝',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_morning',
          'Daily Morning',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> scheduleDailyEveningReminder() async {
    final scheduledTime = _nextInstanceOfTime(
      NotificationConfig.dailyEveningHour,
      NotificationConfig.dailyEveningMinute,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      dailyEveningReminderId,
      'Evening Check-in 🌙',
      'How did your day go?',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_evening',
          'Daily Evening',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ================= WEEKDAY MOTIVATION =================

  static Future<void> scheduleWeekdayMotivationReminders() async {
    final messages = [
      {
        'title': 'Ready to start? 🎯',
        'body': 'Create your first goal today!'
      },
      {
        'title': 'Let’s go! 🚀',
        'body': 'Your success starts with one goal.'
      },
    ];

    final msg = messages[DateTime.now().millisecond % messages.length];

    for (int i = DateTime.monday; i <= DateTime.friday; i++) {
      await _scheduleWeekdayNotification(
        id: motivationMondayId + (i - 1),
        weekday: i,
        title: msg['title']!,
        body: msg['body']!,
      );
    }
  }

  static Future<void> _scheduleWeekdayNotification({
    required int id,
    required int weekday,
    required String title,
    required String body,
  }) async {
    final date = _nextInstanceOfWeekday(
      weekday: weekday,
      hour: NotificationConfig.motivationHour,
      minute: NotificationConfig.motivationMinute,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      date,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'motivation',
          'Motivation',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  // ================= ONGOING ANDROID NOTIFICATION =================

  static Future<void> showOngoingProgress({
    required String todayScore,
    required String totalScore,
    required String goalTitle,
  }) async {
    if (!Platform.isAndroid) return;

    final androidDetails = AndroidNotificationDetails(
      'ongoing_progress',
      'Ongoing Progress',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      styleInformation: BigTextStyleInformation(
        'Today: $todayScore% | Total: $totalScore%',
        contentTitle: '📊 $goalTitle',
      ),
    );

    final details = NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      ongoingProgressId,
      '📊 $goalTitle',
      'Today: $todayScore% | Total: $totalScore%',
      details,
    );
  }

  static Future<void> hideOngoingProgress() async {
    await _flutterLocalNotificationsPlugin.cancel(ongoingProgressId);
  }

  // ================= HELPERS =================

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var date = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (date.isBefore(now)) {
      date = date.add(const Duration(days: 1));
    }
    return date;
  }

  static tz.TZDateTime _nextInstanceOfWeekday({
    required int weekday,
    required int hour,
    required int minute,
  }) {
    var date = _nextInstanceOfTime(hour, minute);
    while (date.weekday != weekday) {
      date = date.add(const Duration(days: 1));
    }
    return date;
  }

  // ================= RESCHEDULE =================

  static Future<void> rescheduleAll() async {
    await _flutterLocalNotificationsPlugin.cancelAll();

    if (_hasActiveGoal()) {
      await scheduleDailyMorningReminder();
      await scheduleDailyEveningReminder();
    } else {
      await scheduleWeekdayMotivationReminders();
    }
  }
}
