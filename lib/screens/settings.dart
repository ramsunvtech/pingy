import 'package:flutter/material.dart';
import 'package:pingy/screens/task/list_activity_type.dart';
import 'task/task_type.dart';

class SettingsScreen extends StatelessWidget {

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
            icon: Icon(Icons.add_task_sharp),
            label: 'Activity Types',
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
        onTap: (int index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (builder) => ActivityTypeListScreen(),
              ),
            );
          }
        }
      ),
    );
  }
}