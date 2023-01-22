import 'package:flutter/material.dart';
import 'taskType.dart';

class HomeScreen extends StatelessWidget {
  static const String _todayMarks = "350";
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
      appBar: AppBar(title: const Text('Pingy')),
      body: ListView.builder(
        itemCount: homePanes.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              // print("tapped");
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
        // onTap: _onItemTapped,
        onTap: (int index) => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (builder) => TaskTypeScreen(),
          ),
        )
      ),
    );
  }
}
