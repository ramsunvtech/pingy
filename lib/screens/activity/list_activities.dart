import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pingy/models/hive/activity.dart';
import 'package:pingy/screens/activity/activity_type.dart';
import 'package:pingy/screens/settings.dart';

class ActivitiesListScreen extends StatefulWidget {
  @override
  _ActivitiesListScreenState createState() => _ActivitiesListScreenState();
}

class _ActivitiesListScreenState extends State<ActivitiesListScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  late final Box activityBox;
  late final Box activityTypeBox;

  @override
  void initState() {
    super.initState();
    // Get reference to an already opened box
    activityBox = Hive.box('activity');
    activityTypeBox = Hive.box('activity_type');
  }

  Widget getListTileTrailingIcon(String activityId) {
    var today = DateTime.now();
    var todayActivityId = 'activity_${today.year}${today.month}${today.day}';

    if (activityId != todayActivityId) {
      return Container();
    }

    return const Icon(
      Icons.delete,
      color: Colors.red,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pingy (Activities)'),
        automaticallyImplyLeading: false,
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
                  Activity activityData = currentBox.getAt(index)!;
                  Map activityTypeBoxMap = activityTypeBox.toMap();
                  Iterable<dynamic> activityTypeBoxMapValues =
                      activityTypeBoxMap.values;

                  // Activity Total Score.
                  dynamic activityTypeFullScore = 0;
                  activityTypeBoxMap.forEach((key, value) {
                    activityTypeFullScore += int.tryParse(value.fullScore)!;
                  });

                  dynamic dayScore = 0;
                  if (activityData.activityItems.isNotEmpty) {
                    activityData.activityItems.forEach((element) {
                      var scoreValue = int.tryParse(element.score ?? "0");

                      if (scoreValue != null) {
                        dayScore += scoreValue;
                      }
                    });
                  }

                  dynamic activityScoreValue =
                      (((dayScore / activityTypeFullScore) * 100).ceil());

                  return InkWell(
                    onTap: () => {},
                    child: ListTile(
                      title: Text('Activity - $activityScoreValue%'),
                      subtitle: Text('$dayScore/$activityTypeFullScore'),
                      trailing: IconButton(
                        onPressed: () {
                          activityBox.delete(activityData.activityId);
                          String toastMessage =
                              'Activity removed successfully!';
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(toastMessage)));
                        },
                        icon: getListTileTrailingIcon(activityData.activityId),
                      ),
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }
}
