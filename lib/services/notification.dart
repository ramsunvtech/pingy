import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:pingy/config/notification_config.dart';
import 'package:pingy/models/hive/rewards.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ================= IDs =================
  static const int dailyMorningReminderId = 100;
  static const int dailyEveningReminderId = 101;

  static const int motivationMondayId = 102;
  static const int motivationTuesdayId = 103;
  static const int motivationWednesdayId = 104;
  static const int motivationThursdayId = 105;
  static const int motivationFridayId = 106;

  static const int ongoingProgressId = 200;

  static const String _ongoingChannelId = 'ongoing_progress';

  // ================= INTERNAL STATE =================
  static bool _ongoingShown = false;
  static bool _userDismissed = false;
  static DateTime? _lastUpdate;

  // ================= INIT =================
  static Future<void> initialize() async {
    tz.initializeTimeZones();

    final timeZoneName = await _getLocalTimeZone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await _plugin.initialize(
      const InitializationSettings(android: androidInit),
    );

    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestPermission();
    }
  }

  // ================= TIMEZONE =================
  static Future<String> _getLocalTimeZone() async {
    try {
      final now = DateTime.now();
      final offset = now.timeZoneOffset;

      if (offset.inMinutes == 480) return 'Asia/Singapore';
      if (offset.inMinutes == 330) return 'Asia/Kolkata';
      if (offset.inHours == 9) return 'Asia/Tokyo';
      if (offset.inHours == 7) return 'Asia/Bangkok';

      return 'UTC';
    } catch (_) {
      return 'UTC';
    }
  }

  // ================= ACTIVE GOAL =================
  static bool _hasActiveGoal() {
    try {
      final box = Hive.box('rewards');
      if (box.isEmpty) return false;

      final today = DateTime.now();
      final d = DateTime(today.year, today.month, today.day);

      for (final g in box.values.cast<RewardsModel>()) {
        final s = _parseDate(g.startPeriod);
        final e = _parseDate(g.endPeriod);
        if (!d.isBefore(s) && !d.isAfter(e)) return true;
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

  // ================= ONGOING (THE IMPORTANT PART) =================

  /// 🔴 CALL THIS ONLY FROM BUSINESS LOGIC
  static Future<void> updateOngoingProgress({
    required String goalTitle,
    required String todayScore,
    required String totalScore,
    required String nextActivity,
    required int completed,
    required int total,
  }) async {
    if (!Platform.isAndroid) return;
    if (_userDismissed) return;

    // 🔒 HARD THROTTLE
    if (_lastUpdate != null &&
        DateTime.now().difference(_lastUpdate!).inSeconds < 15) {
      return;
    }
    _lastUpdate = DateTime.now();

    final firstShow = !_ongoingShown;

    final androidDetails = AndroidNotificationDetails(
      _ongoingChannelId,
      'Daily Progress',

      // 🔐 Lock screen allowed ONLY on first show
      importance: firstShow ? Importance.high : Importance.low,
      priority: firstShow ? Priority.high : Priority.low,

      visibility: NotificationVisibility.public,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      onlyAlertOnce: true,

      category: AndroidNotificationCategory.progress,
      icon: '@mipmap/ic_launcher',

      styleInformation: BigTextStyleInformation(
        '📊 Today: $todayScore% | Overall: $totalScore%\n'
        '✅ Completed: $completed/$total\n'
        '⏭️ Next: $nextActivity',
        contentTitle: goalTitle,
      ),
    );

    await _plugin.show(
      ongoingProgressId,
      goalTitle,
      '⏭️ Next: $nextActivity',
      NotificationDetails(android: androidDetails),
    );

    _ongoingShown = true;
  }

  /// Called ONLY when user explicitly disables it
  static Future<void> hideOngoingProgress() async {
    _userDismissed = true;
    _ongoingShown = false;
    _lastUpdate = null;
    await _plugin.cancel(ongoingProgressId);
  }

  /// Call at new day / new goal
  static void resetOngoing() {
    _userDismissed = false;
    _ongoingShown = false;
    _lastUpdate = null;
  }

  // ================= DAILY REMINDERS =================

  static Future<void> scheduleDailyMorningReminder() async {
    final time = _nextInstanceOfTime(
      NotificationConfig.dailyMorningHour,
      NotificationConfig.dailyMorningMinute,
    );

    await _plugin.zonedSchedule(
      dailyMorningReminderId,
      'Time to update your progress! 🌅',
      'Don\'t forget to log today\'s activities 📝',
      time,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_morning',
          'Daily Morning',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> scheduleDailyEveningReminder() async {
    final time = _nextInstanceOfTime(
      NotificationConfig.dailyEveningHour,
      NotificationConfig.dailyEveningMinute,
    );

    await _plugin.zonedSchedule(
      dailyEveningReminderId,
      'Evening Check-in 🌙',
      'How did your day go?',
      time,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_evening',
          'Daily Evening',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ================= HELPERS =================

  static tz.TZDateTime _nextInstanceOfTime(int h, int m) {
    final now = tz.TZDateTime.now(tz.local);
    var d = tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
    if (d.isBefore(now)) d = d.add(const Duration(days: 1));
    return d;
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static Future<void> rescheduleAll() async {
    await cancelAll();
    resetOngoing();

    if (_hasActiveGoal()) {
      await scheduleDailyMorningReminder();
      await scheduleDailyEveningReminder();
    }
  }
}
