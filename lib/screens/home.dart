import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  int _selectedIndex = 0;
  // int currentScore = 50;
  // int targetScore = 90;

  @override
  void _onItemTapped(int index) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pingy')),
      body: const Center(
          child: Image(
            image: AssetImage('assets/cute.webp'),
          ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
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
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
