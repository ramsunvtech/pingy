import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(
    PingyApp(),
  );
}

class PingyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
          appBar: AppBar(
              title: const Text('Pingy App')
          ),
        )
    );
  }
}

// Text('Hello Pingy Rewards')
// PingyApp
