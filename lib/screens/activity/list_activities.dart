import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pingy/screens/activity/activity_type.dart';

class ActivitiesListScreen extends StatefulWidget {
  @override
  _ActivitiesListScreenState createState() => _ActivitiesListScreenState();
}

class _ActivitiesListScreenState extends State<ActivitiesListScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  late final Box activityBox;

  @override
  void initState() {
    super.initState();
    // Get reference to an already opened box
    activityBox = Hive.box('activity');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pingy (Activities)'),
      ),
      body: ValueListenableBuilder(
        valueListenable: activityBox.listenable(),
        builder: (context, Box box, widget) {
          if (box.isEmpty) {
            return const Center(
              child: Text('No Activities are available.'),
            );
          } else {
            return RefreshIndicator(
                key: _refreshIndicatorKey,
                color: Colors.white,
                backgroundColor: Colors.blue,
                strokeWidth: 4.0,
                onRefresh: () async {
                  // Replace this delay with the code to be executed during refresh
                  // and return a Future when code finish execution.
                  return Future<void>.delayed(const Duration(seconds: 3));
                },
                // Pull from top to show refresh indicator.
                child: ListView.builder(
                  itemCount: activityBox.length,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    var currentBox = activityBox;
                    var activityData = currentBox.getAt(index)!;
                    return InkWell(
                      onTap: () => {},
                      child: ListTile(
                        title: Text('activityData.name'),
                        subtitle: Text(activityData.score),
                        trailing: IconButton(
                          onPressed: () => {},
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (builder) => TaskTypeScreen(),
            ),
          );
        },
        child: const Icon(Icons.task),
        backgroundColor: Colors.green,
      ),
    );
  }
}
