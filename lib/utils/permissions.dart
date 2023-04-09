import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

Future askCameraPermission() async {
  if (!kIsWeb) {
    if (await Permission.camera.request().isGranted) {}
  }
}

/// Checks the notification permission status
Future<String> getCheckNotificationPermStatus() async {
  if (!kIsWeb) {
    if (await Permission.notification.request().isGranted) {
      String notificationPermissionStatus =
      Permission.notification.status as String;

      return notificationPermissionStatus;
    }

    return '';
  }

  return '';
}