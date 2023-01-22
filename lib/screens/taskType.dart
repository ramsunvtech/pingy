import 'package:flutter/material.dart';

class TaskTypeScreen extends StatelessWidget {
  void _onItemTapped(int index) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pingy (Task Type)')),
      body: const Center(
        child: Text('Task Type Form'),
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
        onTap: _onItemTapped,
      ),
    );
  }
}