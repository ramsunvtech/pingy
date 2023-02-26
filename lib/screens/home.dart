import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pingy/models/hive/activity.dart';
import 'package:pingy/models/hive/activity_item.dart';
import 'package:pingy/models/hive/activity_type.dart';
import 'package:pingy/models/hive/rewards.dart';
import 'package:pingy/screens/activity/activity_type.dart';
import 'package:pingy/screens/activity/update_activity.dart';
import 'package:pingy/screens/rewards/rewards.dart';
import 'settings.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Box rewardBox;
  late final Box activityBox;
  late final Box activityTypeBox;

  String todayScore = '0';
  String totalScore = '0';
  String predictReward = 'none';
  bool containsRewards = false;
  bool containsTypes = false;

  List<Widget> getHomeBlocks(String score) {
    final List<Widget> homePanes = [
      const Center(
        child: CircleAvatar(
          radius: 160,
          backgroundImage: AssetImage('assets/cute.webp'),
        ),
      ),
      if(containsRewards && containsTypes) Center(
        child: Text(
          'Today Score: $todayScore%',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
            fontStyle: FontStyle.italic,
            color: Colors.blue,
          ),
        ),
      ),
      if(containsRewards && containsTypes) Center(
        child: Text(
          'Total Score: $totalScore%',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 34,
            fontStyle: FontStyle.italic,
            color: Colors.blue,
          ),
        ),
      ),
      if(containsRewards && containsTypes) Center(
        child: Text(
          'Your Reward: $predictReward',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 40,
            fontStyle: FontStyle.italic,
            color: Colors.redAccent,
          ),
        ),
      ),
      // const Center(
      //   child: ClipRect(
      //     borderRadius: BorderRadius.circular(300),
      //     child: AssetImage('assets/ipad.jpg'),
      //   ),
      // ),
      if(!containsRewards) ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (builder) => RewardsScreen(),
            ),
          );
        },
        child: const Text('Add your Reward details'),
      ),
      if(containsRewards && !containsTypes) ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (builder) => TaskTypeScreen(),
            ),
          );
        },
        child: const Text('Add your Activity Types'),
      ),
    ];

    return homePanes;
  }

  @override
  void initState() {
    super.initState();
    // Get reference to an already opened box
    rewardBox = Hive.box('rewards');
    activityBox = Hive.box('activity');
    activityTypeBox = Hive.box('activity_type');

    Map activityBoxMap = activityBox.toMap();
    Iterable<dynamic> activityBoxMapValues = activityBoxMap.values;

    Map activityTypeBoxMap = activityTypeBox.toMap();
    Iterable<dynamic> activityTypeBoxMapValues = activityTypeBoxMap.values;

    Map rewardBoxMap = rewardBox.toMap();
    if (rewardBoxMap.isNotEmpty) {
      containsRewards = true;
      RewardsModel rewardDetails = rewardBoxMap.values.first;

      // print('rewards');
      // print('${rewardDetails.firstPrice}');
    }

    int activityTypeFullScore = 0;
    activityTypeBoxMap.forEach((key, value) {
      activityTypeFullScore += int.tryParse(value.fullScore)!;
    });

    // print("activityTypeFullScore");
    // print(activityTypeFullScore);

    if (activityTypeFullScore > 0) {
      containsTypes = true;

      var today = DateTime.now();
      var lastActivityId = 'activity_${today.year}${today.month}23';
      var todayActivityId = 'activity_${today.year}${today.month}${today.day}';

      if (activityBoxMapValues.isNotEmpty) {
        // print("activityBoxMapValues");
        dynamic totalActivityScore = 0;
        activityBoxMapValues.forEach((activity) {
          // print(activity.activityId);
          if (activity.activityId != todayActivityId) {
            int dayScore = 0;
            activity.activityItems.forEach((element) {
              var scoreValue = int.tryParse(element.score ?? "0");

              if (scoreValue != null) {
                dayScore += scoreValue;
              }
              // print('score: ${element.score}');
            });

            // print ('day score');
            // print(dayScore);

            dynamic todayScoreValue =
            (((dayScore / activityTypeFullScore) * 100).ceil());

            // print ('todayScoreValue');
            // print(todayScoreValue);

            if (activity.activityId == todayActivityId && todayScoreValue != '') {
              todayScore = todayScoreValue.toString();
            } else if (todayScoreValue != '') {
              totalActivityScore += todayScoreValue;
            }

            if (todayScoreValue > 0) {
              // print('dayScore: ${activity.activityId} $dayScore - $todayScoreValue%');
            }
          }
        });

        // print('totalActivityScore: $totalActivityScore');

        int totalActivityDays = activityBoxMapValues.length - 1;

        dynamic rewardScore =
        ((totalActivityScore) / (100 * totalActivityDays) * 100);

        // print('rewardScore');
        // print(rewardScore);
        if (rewardScore > 0) {
          totalScore = rewardScore.toString();
        }
      }
    }
  }

  @override
  void dispose() {
    // Close Hive Connection.
    Hive.close();

    super.dispose();
  }

  Widget getFloatingButton(BuildContext context) {
    if (!containsRewards && !containsTypes) {
      return Container();
    }

    return FloatingActionButton(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> homePanes = getHomeBlocks('100');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pingy'),
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
      body: ListView.builder(
        itemCount: homePanes.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            child: new Padding(
              padding: const EdgeInsets.all(8.0),
              child: new Container(
                child: homePanes[index],
              ),
            ),
          );
        },
      ),
      floatingActionButton: getFloatingButton(context),
    );
  }
}
