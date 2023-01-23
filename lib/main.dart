import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';

// Screen Imports.
import 'screens/home.dart';

void main() async {
  // Initialize hive.
  await Hive.initFlutter();

  // Open Box.
  var box = await Hive.openBox('Task');

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
