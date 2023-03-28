import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static void initialize() {
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    _flutterLocalNotificationsPlugin.initialize(initializationSettings);
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
