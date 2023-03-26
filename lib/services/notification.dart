import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static void initialize() {
    const InitializationSettings initializationSettings =
        InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'));
    _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  static void display() async {
    try {
      Random random = Random();
      int id = random.nextInt(1000);
      const NotificationDetails notificationDetails = NotificationDetails(
          android: AndroidNotificationDetails('mychannel', 'my chanel',
              importance: Importance.max, priority: Priority.high));

      await _flutterLocalNotificationsPlugin.show(
          id,
          'message.notification.title',
          'message.notification.body',
          notificationDetails);
    } catch (e) {
      print('Error>>>$e');
    }
  }
}
