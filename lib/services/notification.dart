import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

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

  static void display() async {
    try {
      Random random = Random();
      int id = random.nextInt(1000);
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails('my-channel', 'my chanel',
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

      await _flutterLocalNotificationsPlugin.show(
          id, 'your title', 'your body', notificationDetails);
    } catch (e) {
      print('Error>>>$e');
    }
  }
}
