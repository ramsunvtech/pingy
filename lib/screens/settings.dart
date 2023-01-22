import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {

  // @override
  void _onItemTapped(int index) {
    // print(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pingy (Settings)')),
      body: const Center(
        child: Text('Settings Screen'),
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
        // currentIndex: _selectedIndex,
        onTap: _onItemTapped
      ),
    );
  }
}