import 'package:flutter/material.dart';

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
        appBar: AppBar(title: const Text('Pingy App')),
        body: const Center(
            child: Image(
          image: AssetImage('assets/cute.webp'),
        )),
        bottomNavigationBar: const BottomNavigationBar(items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Task Types',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Rewards',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Task',
          ),
        ]),
      ),
    );
  }
}

// Text('Hello Pingy Rewards')
// PingyApp
