import 'package:flutter/material.dart';
import 'package:pingy/screens/task/update_task.dart';
import 'settings.dart';
import 'task/task_type.dart';

class HomeScreen extends StatelessWidget {
  static const String _todayMarks = "430";
  static const String _todayScore = "70";
  static const String _totalScore = "90";

  final List<Widget> homePanes = [
    const Center(
      child: Image(
        image: AssetImage('assets/cute.webp'),
      ),
    ),
    const Center(
      child: Text(
        'Today Marks: $_todayMarks',
        style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
            fontStyle: FontStyle.italic),
      ),
    ),
    const Center(
      child: Text(
        'Today Score: $_todayScore%',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 25,
          fontStyle: FontStyle.italic,
          color: Colors.blue,
        ),
      ),
    ),
    const Center(
      child: Text(
        'Total Score: $_totalScore%',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 34,
          fontStyle: FontStyle.italic,
          color: Colors.blue,
        ),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pingy'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (builder) => SettingsScreen(),
                ),
              );
            },
          )
        ],
      ),
      body: ListView.builder(
        itemCount: homePanes.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              if (index == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (builder) => TaskTypeScreen(),
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                child: homePanes[index],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (builder) => UpdateTaskScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }
}
