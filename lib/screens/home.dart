import 'package:flutter/material.dart';
import 'taskType.dart';

class HomeScreen extends StatelessWidget {
  // int _selectedIndex = 0;
  // int currentScore = 50;
  // String targetScore = '95';

  // @override
  // void _onItemTapped(int index, BuildContext context) {
  //   Navigator.push(context,
  //       MaterialPageRoute(builder: (builder) => TaskTypeScreen()));
  // }

  final List<Widget> homePanes = [
    const Center(
      child: Image(
        image: AssetImage('assets/cute.webp'),
      ),
    ),
    const Center(
      child: Text(
        'Current Score: 50%',
        style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
            fontStyle: FontStyle.italic),
      ),
    ),
    const Center(
      child: Text(
        'Target Score: 90%',
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
        onTap: (int index) => Navigator.push(context,
    MaterialPageRoute(builder: (builder) => TaskTypeScreen())),
      ),
    );
  }
}
