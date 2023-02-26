import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pingy/screens/activity/activity_type.dart';
import 'package:pingy/screens/home.dart';

class ActivityTypeListScreen extends StatefulWidget {
  @override
  _ActivityTypeListScreenState createState() => _ActivityTypeListScreenState();
}

class _ActivityTypeListScreenState extends State<ActivityTypeListScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  late final Box activityTypeBox;

  String activityTypeCount = '0';

  @override
  void initState() {
    super.initState();
    // Get reference to an already opened box
    activityTypeBox = Hive.box('activity_type');

    if(activityTypeBox.isNotEmpty) {
      activityTypeCount = activityTypeBox.length.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pingy (Activity Types - $activityTypeCount)'),
      ),
      body: ValueListenableBuilder(
        valueListenable: activityTypeBox.listenable(),
        builder: (context, Box box, widget) {
          if (box.isEmpty) {
            return const Center(
              child: Text('Add your first Activity Type and have Fun!'),
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
                  itemCount: activityTypeBox.length,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    var currentBox = activityTypeBox;
                    var activityTypeData = currentBox.getAt(index)!;
                    return InkWell(
                      onTap: () => {},
                      child: ListTile(
                        title: Text(activityTypeData.activityName),
                        subtitle: Text(activityTypeData.fullScore),
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
        child: const Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }
}
