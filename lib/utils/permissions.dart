import 'package:permission_handler/permission_handler.dart';

Future askCameraPermission() async {
  if (await Permission.camera.request().isGranted) {}
}

/// Checks the notification permission status
Future<String> getCheckNotificationPermStatus() async {
  if (await Permission.notification.request().isGranted) {
    String notificationPermissionStatus =
    Permission.notification.status as String;

    return notificationPermissionStatus;
  }

  return '';
}