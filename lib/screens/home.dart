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
  String predictReward = '';
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
      if(containsRewards && containsTypes && predictReward != '') Center(
        child: Text(
          predictReward,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontStyle: FontStyle.italic,
            color: Colors.redAccent,
          ),
        ),
      ),
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

  Future<void> _updateScores() async {
    // Get reference to an already opened box
    rewardBox = Hive.box('rewards');
    activityBox = Hive.box('activity');
    activityTypeBox = Hive.box('activity_type');

    var today = DateTime.now();
    var activityId = 'activity_${today.year}${today.month}${today.day}';
    bool canCreateNewActivity = true;

    Map rewardBoxMap = rewardBox.toMap();
    if (rewardBoxMap.isNotEmpty) {
      containsRewards = true;
    }

    if(activityTypeBox.isNotEmpty) {
      containsTypes = true;
    }

    if (rewardBox.isEmpty || activityTypeBox.isEmpty) {
      canCreateNewActivity = false;
    }

    if (activityBox.containsKey(activityId)) {
      // print('Log: Today Activity is exist');
      Activity todayActivity = activityBox.get(activityId);
      if (todayActivity.activityItems.isNotEmpty) {
        // print('Log: Today Activity Type is not empty');
        canCreateNewActivity = false;
      }
    }

    if(canCreateNewActivity) {
      final activityTypeKeys = activityTypeBox.keys;
      final List<ActivityItem> activityItems = [];
      for (var activityTypeKey in activityTypeKeys) {
        ActivityItem newActivityItem = ActivityItem(activityTypeKey, '');
        activityItems.add(newActivityItem);
      }
      Activity newActivity = Activity(activityId, activityItems, '', DateTime.now());
      activityBox.put(activityId, newActivity);
    }

    Map activityBoxMap = activityBox.toMap();
    Iterable<dynamic> activityBoxMapValues = activityBoxMap.values;

    Map activityTypeBoxMap = activityTypeBox.toMap();
    Iterable<dynamic> activityTypeBoxMapValues = activityTypeBoxMap.values;

    dynamic activityTypeFullScore = 0;
    activityTypeBoxMap.forEach((key, value) {
      activityTypeFullScore += int.tryParse(value.fullScore)!;
    });

    // print('activityTypeFullScore: $activityTypeFullScore');

    // Check Activity Types are exist and scores is greater than zero.
    if (activityTypeFullScore > 0) {
      var today = DateTime.now();
      var todayActivityId = 'activity_${today.year}${today.month}${today.day}';

      // print('Today ActivityId: $todayActivityId');
      // print('Activity Count: ${activityBoxMapValues.length}');

      dynamic todayScoreValue = 0;

      if (activityBoxMapValues.isNotEmpty) {
        // print("activityBoxMapValues is exist");
        dynamic totalActivityScore = 0;
        activityBoxMapValues.forEach((activity) {
          // print('Activitiy Id: ${activity.activityId}');
          dynamic dayScore = 0;
          if (activity.activityItems.length > 0) {
            activity.activityItems.forEach((element) {
              // print('Activity Item Score: ${element.score}');
              var scoreValue = int.tryParse(element.score ?? "0");

              if (scoreValue != null) {
                dayScore += scoreValue;
              }
              // print('score: ${element.score}');
            });

            // print ('day score: $dayScore');

            dynamic todayScoreValue = (((dayScore / activityTypeFullScore) * 100).ceil());
            // print ('todayScoreValue: $todayScoreValue');

            if (activity.activityId == todayActivityId && todayScoreValue != '') {
              totalActivityScore += todayScoreValue;
              todayScore = todayScoreValue.toString();
            } else if (todayScoreValue != '') {
              totalActivityScore += todayScoreValue;
            }
          }



          if (todayScoreValue > 0) {
            // print('dayScore: ${activity.activityId} $dayScore - $todayScoreValue%');
          }
        });

        // print('totalActivityScore: $totalActivityScore');

        dynamic totalActivityDays = activityBoxMapValues.length;

        // print('totalActivityDays: $totalActivityDays');

        dynamic rewardScore = 0;

        if (totalActivityScore > 0 && totalActivityScore > 0) {
          rewardScore = ((totalActivityScore) / (100 * totalActivityDays) * 100).ceil();
        }

        // print('rewardScore: $rewardScore');
        if (rewardScore > 0) {
          totalScore = rewardScore.toString();

          if (rewardBoxMap.isNotEmpty) {
            RewardsModel rewardDetails = rewardBoxMap.values.first;

            if (rewardScore >= 95) {
              predictReward = rewardDetails.firstPrice;
            } else if (rewardScore >= 85) {
              predictReward = rewardDetails.secondPrice;
            } else if (rewardScore >= 75) {
              predictReward = rewardDetails.thirdPrice;
            }

            List endPeriod = rewardDetails.endPeriod.split('/').toList();
            String todayDate = '${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}';
            DateTime endDate = DateTime.parse('${endPeriod[2]}-${endPeriod[1]}-${endPeriod[0]}');
            Duration diff = endDate.difference(today);

            if (predictReward.isNotEmpty) {
              if (diff.inDays < 0) {
                 predictReward = 'Already Won $predictReward Reward!';
              } else if (diff.inDays == 0) {
                predictReward = 'Won $predictReward Reward, Congrats!';
              } else {
                predictReward = '$predictReward Reward on your way!';
              }
            } else {
              if (diff.inDays < 0) {
                predictReward = '${rewardDetails.title} programme Activity Period (${rewardDetails.startPeriod} to ${rewardDetails.endPeriod}) is over Try again!';
              } else if (diff.inDays == 0) {
                predictReward = 'Last day of ${rewardDetails.title} programme';
              } else {
                predictReward = 'Reward on your way!';
              }
            }
          }
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _updateScores();
  }

  @override
  void dispose() {
    // Close Hive Connection.
    Hive.close();

    super.dispose();
  }

  Widget getFloatingButton(BuildContext context) {
    if (!containsRewards || !containsTypes || activityBox.length == 0) {
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
