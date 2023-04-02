import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  DateTime nextInstanceOfTenAM(int hour, int minutes) {
    final DateTime now = DateTime.now();
    final DateTime tenAM = DateTime(now.year, now.month, now.day, hour, minutes);
    return tenAM.isBefore(now) ? tenAM.add(const Duration(days: 1)) : tenAM;
  }

  static void initialize() {
    DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
            onDidReceiveLocalNotification: (int id, String? title, String? body,
                String? payload) async {});

    InitializationSettings initializationSettings = InitializationSettings(
      android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: initializationSettingsIOS,
    );

    _flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse:
            (NotificationResponse notificationResponse) async {});
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

  scheduleNotification({
    required int id,
    String? title,
    String? body,
    String? payload,
    required DateTime scheduledNotificationDateTime,
  }) async {
    await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(
          scheduledNotificationDateTime,
          tz.local,
        ),
        getNotificationDetails(),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidAllowWhileIdle: true);
  }
}
