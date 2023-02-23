import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pingy/screens/activity/update_activity.dart';
import 'settings.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Box activityBox;

  static const String _todayMarks = "430";
  static const String _todayScore = "70";
  static const String _totalScore = "90";

  final List<Widget> homePanes = [
    const Center(
      child: CircleAvatar(
        radius: 160,
        backgroundImage: AssetImage('assets/cute.webp'),
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
  void initState() {
    super.initState();
    // Get reference to an already opened box
    activityBox = Hive.box('activity');
  }

  @override
  void dispose() {
    // Close Hive Connection.
    Hive.close();

    super.dispose();
  }

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
              print("tapped");
            },
            child: new Padding(
              padding: const EdgeInsets.all(8.0),
              child: new Container(
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
        child: const Icon(Icons.edit),
        backgroundColor: Colors.green,
      ),
    );
  }
}
