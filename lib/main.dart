import 'package:flutter/material.dart';

// Screen Imports.
import 'screens/home.dart';

void main() {
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
