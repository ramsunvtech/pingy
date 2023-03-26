import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';

import 'package:pingy/models/hive/activity.dart';
import 'package:pingy/models/hive/activity_item.dart';
import 'package:pingy/models/hive/rewards.dart';
import 'package:pingy/services/notfication.dart';
import 'package:pingy/utils/navigators.dart';
import 'package:pingy/widgets/icons/settings.dart';

import 'package:pingy/utils/l10n.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  NotificationService notificationService = NotificationService();

  String _goalPicture = '';
  bool _goalPictureSelected = false;
  final ImagePicker goalPicturePicker = ImagePicker();

  late final Box rewardBox;
  late final Box activityBox;
  late final Box activityTypeBox;

  String todayScore = '0';
  String totalScore = '0';
  String predictReward = '';
  bool containsRewards = false;
  bool containsTypes = false;

  Future getGoalImage() async {
    try {
      final pickedGoalImage = await goalPicturePicker.pickImage(
        source: ImageSource.camera,
      );
      if (pickedGoalImage == null) return;

      String filePath = pickedGoalImage!.path;

      RewardsModel goalDetails = rewardBox.values.last;
      RewardsModel editedGoalDetails = RewardsModel(
          goalDetails.title,
          goalDetails.startPeriod,
          goalDetails.endPeriod,
          goalDetails.firstPrice,
          goalDetails.secondPrice,
          goalDetails.thirdPrice,
          filePath);
      rewardBox.putAt(rewardBox.keys.last, editedGoalDetails);

      setState(() {
        _goalPicture = pickedGoalImage!.path;
        _goalPictureSelected = true;
      });
    } on PlatformException catch (e) {
      print('Failed to pick image: $e');
    }
  }

  Widget getSelectedImage() {
    if (_goalPictureSelected || _goalPicture.isNotEmpty) {
      File goalPictureFile = File(_goalPicture);
      if (goalPictureFile.existsSync()) {
        return CircleAvatar(
            radius: 160 - 5,
            backgroundImage: Image.file(
              goalPictureFile,
              fit: BoxFit.cover,
            ).image);
      }
    }

    return SizedBox(
      width: double.infinity,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: const Icon(
          Icons.camera_alt,
          size: 100.0,
          color: Colors.white,
        ),
        tooltip: 'Capture Picture for your Goal',
        onPressed: () {  },
      ),
    );
  }

  List<Widget> getHomeBlocks(String score) {
    final List<Widget> homePanes = [
      ElevatedButton(
        onPressed: () {
          notificationService.sendNotification();
        },
        child: const Text('Show Notification'),
      ),
      if (containsRewards && containsTypes && getGoalEndDayCount() > 0) Center(
        child: GestureDetector(
          onTap: () async {
            await getGoalImage();
          },
          child: CircleAvatar(
            backgroundColor: Colors.grey,
            radius: 160,
            child: getSelectedImage(),
          ),
        ),
      ),
      if (containsRewards && containsTypes && getGoalEndDayCount() > 0)
        Center(
          child: Text(
            '${AppLocalizations.of(context).todayScore(todayScore)}%',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 25,
              fontStyle: FontStyle.italic,
              color: Colors.blue,
            ),
          ),
        ),
      if (containsRewards && containsTypes && getGoalEndDayCount() > 0)
        Center(
          child: Text(
            'Total Score: $totalScore%',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 34,
              fontStyle: FontStyle.italic,
              color: Colors.blue,
            ),
          ),
        ),
      if (containsRewards && containsTypes && predictReward != '')
        Center(
          child: Text(
            predictReward,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              fontStyle: FontStyle.italic,
              color: Colors.redAccent,
            ),
          ),
        ),
      if (!containsRewards || getGoalEndDayCount() < 0)
        ElevatedButton(
          onPressed: () {
            goToGoalsForm(context);
          },
          child: Text(t(context).addGoals),
        ),
      if (containsRewards && !containsTypes)
        ElevatedButton(
          onPressed: () {
            goToActivityTypeFormScreen(context);
          },
          child: Text(t(context).addActivityTypes),
        ),
    ];

    return homePanes;
  }

  int getGoalEndDayCount() {
    Map rewardBoxMap = rewardBox.toMap();
    RewardsModel rewardDetails = rewardBoxMap.values.last;

    DateTime today = DateTime.now();
    List endPeriod = rewardDetails.endPeriod.split('/').toList();
    DateTime endDate =
        DateTime.parse('${endPeriod[2]}-${endPeriod[1]}-${endPeriod[0]}');
    Duration diff = endDate.difference(today);
    return diff.inDays;
  }

  void setGoalPicturePath(RewardsModel rewardDetails) {
    if (rewardDetails.rewardPicture != '') {
      _goalPicture = rewardDetails.rewardPicture!;
    }
  }

  Future<void> _updateScores() async {
    // Get reference to an already opened box
    rewardBox = Hive.box('rewards');
    activityBox = Hive.box('activity');
    activityTypeBox = Hive.box('activity_type');

    DateTime today = DateTime.now();
    var activityId = 'activity_${today.year}${today.month}${today.day}';
    bool canCreateNewActivity = true;

    Map rewardBoxMap = rewardBox.toMap();
    if (rewardBoxMap.isNotEmpty) {
      containsRewards = true;
    }

    if (activityTypeBox.isNotEmpty) {
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

    if (canCreateNewActivity) {
      final activityTypeKeys = activityTypeBox.keys;
      final List<ActivityItem> activityItems = [];
      for (var activityTypeKey in activityTypeKeys) {
        ActivityItem newActivityItem = ActivityItem(activityTypeKey, '');
        activityItems.add(newActivityItem);
      }
      Activity newActivity =
          Activity(activityId, activityItems, '', DateTime.now());
      activityBox.put(activityId, newActivity);
    }

    Map activityBoxMap = activityBox.toMap();
    // TODO: Filter with latest goal period.
    Iterable<dynamic> activityBoxMapValues = activityBoxMap.values;

    Map activityTypeBoxMap = activityTypeBox.toMap();

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
          // print('Activity Id: ${activity.activityId}');
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

            dynamic todayScoreValue =
                (((dayScore / activityTypeFullScore) * 100).ceil());
            // print ('todayScoreValue: $todayScoreValue');

            if (activity.activityId == todayActivityId &&
                todayScoreValue != '') {
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
          rewardScore =
              ((totalActivityScore) / (100 * totalActivityDays) * 100).ceil();
        }

        if (rewardScore > 0) {
          totalScore = rewardScore.toString();

          if (rewardBoxMap.isNotEmpty) {
            // TODO: Fix to get iterated / active Reward details instead of first one.
            RewardsModel rewardDetails = rewardBoxMap.values.last;

            setGoalPicturePath(rewardDetails);

            if (rewardScore >= 95) {
              predictReward = rewardDetails.firstPrice;
            } else if (rewardScore >= 85) {
              predictReward = rewardDetails.secondPrice;
            } else if (rewardScore >= 75) {
              predictReward = rewardDetails.thirdPrice;
            }

            int goalEndDayCount = getGoalEndDayCount();

            if (predictReward.isNotEmpty) {
              if (goalEndDayCount < 0) {
                predictReward = 'Already Won $predictReward Reward!';
              } else if (goalEndDayCount == 0) {
                predictReward = 'Won $predictReward Reward, Congrats!';
              } else {
                predictReward = '$predictReward Reward on your way!';
              }
            } else {
              if (goalEndDayCount < 0) {
                predictReward =
                    '${rewardDetails.title} Goal Activity Period (${rewardDetails.startPeriod} to ${rewardDetails.endPeriod}) ended \n'
                    ' Try create new Goal!';
              } else if (goalEndDayCount == 0) {
                predictReward = 'Last day of ${rewardDetails.title} Goal';
              } else {
                predictReward = 'Reward on your way!';
              }
            }
          }
        } else {
          predictReward = 'Start update your Activities';
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    notificationService.initialiseNotifications();
    _updateScores();
  }

  @override
  void dispose() {
    // Close Hive Connection.
    Hive.close();

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
    }
  }

  Widget getFloatingButton(BuildContext context) {
    if (!containsRewards || !containsTypes || activityBox.length == 0) {
      return Container();
    }

    return FloatingActionButton(
      onPressed: () {
        goToUpdateActivityScreen(context);
      },
      backgroundColor: Colors.green,
      child: const Icon(Icons.edit),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> homePanes = getHomeBlocks('100');

    return WillPopScope(
      child: Scaffold(
        appBar: AppBar(
          title: Text(t(context).homePageTitle),
          automaticallyImplyLeading: false,
          actions: [
            if (containsRewards && containsTypes)
              settingsLinkIconButton(context),
          ],
        ),
        body: ListView.builder(
          itemCount: homePanes.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  child: homePanes[index],
                ),
              ),
            );
          },
        ),
        floatingActionButton: getFloatingButton(context),
      ),
      onWillPop: () async {
        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
        return false;
      },
    );
  }
}
