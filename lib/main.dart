import 'package:flutter/material.dart';
// import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Screen Imports.
import 'screens/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize hive.
  await Hive.initFlutter();

  // Open Box.
  var activityBox = await Hive.openBox('activity');
  var todayDate = DateTime.now();
  var activityKey = '${todayDate.year}${todayDate.month}${todayDate.day}';
// print (activityKey);
  activityBox.put(activityKey, 'Good');

  // print('$activityKey: ${activityBox.get(activityKey)}');

  runApp(
    PingyApp(),
  );
}

class PingyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

// Text('Hello Pingy Rewards')
// PingyApp
