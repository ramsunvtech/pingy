import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';

import 'package:pingy/widgets/icons/settings.dart';
import 'package:pingy/widgets/FutureWidgets.dart';
import 'package:pingy/widgets/PercentageIndicator.dart';
import 'package:pingy/widgets/GreyCard.dart';
import 'package:pingy/widgets/CustomAppBar.dart';

import 'package:pingy/models/hive/activity.dart';
import 'package:pingy/models/hive/activity_item.dart';
import 'package:pingy/models/hive/rewards.dart';
import 'package:pingy/utils/navigators.dart';
import 'package:pingy/utils/l10n.dart';
import 'package:pingy/utils/color.dart';
import 'package:pingy/utils/permissions.dart';

import 'package:pingy/services/goals.dart';

import '../services/activity.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  String _goalPicture = '';
  bool _goalPictureSelected = false;
  final bool _canDebug = true;
  bool _isGoalEnded = false;
  final ImagePicker goalPicturePicker = ImagePicker();

  late final Box rewardBox;
  late final Box activityBox;
  late final Box activityTypeBox;

  late Future<String> permissionStatusFuture;

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
      String rewardId = goalDetails?.rewardId?.toString() ?? '';
      String yetToWin = '';
      RewardsModel editedGoalDetails = RewardsModel(
          goalDetails.title,
          goalDetails.startPeriod,
          goalDetails.endPeriod,
          goalDetails.firstPrice,
          goalDetails.secondPrice,
          goalDetails.thirdPrice,
          filePath,
          rewardId,
          yetToWin);
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
            radius: 120 - 5,
            backgroundImage: Image.file(
              goalPictureFile,
              fit: BoxFit.cover,
            ).image);
      }
    }

    return SizedBox(
        width: double.infinity,
        child: CircleAvatar(
          radius: 110,
          backgroundColor: greyColor,
          child: Icon(
            Icons.camera_alt,
            size: 70.0,
            color: darkGreyColor,
          ),
        ));
  }

  String getGoalDetails(goalFieldName) {
    RewardsModel goalDetails = rewardBox.values.last;
    switch (goalFieldName) {
      case 'title':
        return goalDetails.title;
      case 'period':
        return '${goalDetails.startPeriod} to ${goalDetails.endPeriod}';
      default:
        return '';
    }
  }

  List<Widget> getHomeBlocks(String score) {
    Map<String, dynamic> scoreDetails = getScoreDetails();
    String todayScoreValue = scoreDetails['todayScore'] ?? '0';
    String totalActivities = scoreDetails['totalActivities'] ?? '-';
    String maximumTotalScore = scoreDetails['maximumTotalScore'] ?? '-';
    String actualTotalScore = scoreDetails['actualTotalScore'] ?? '-';
    RewardsModel currentGoal = getCurrentGoal();
    RewardsModel lastGoal = getLastCompletedGoal();

    Widget todayScoreIndicator = (hasNoGoalInProgress())
        ? const Padding(padding: EdgeInsets.only(left: 75.0))
        : percentageIndicator(50.0, todayScoreValue, 'Today Score');
    Widget totalScoreIndicator = percentageIndicator(70.0, totalScore,
        (hasNoGoalInProgress()) ? 'Your Last Score' : 'Total Score');

    final List<Widget> homePanes = [
      if (containsRewards && containsTypes)
        Center(
          child: GestureDetector(
            onTap: () async {
              await getGoalImage();
            },
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 120, // (115+5)
              child: getSelectedImage(),
            ),
          ),
        ),
      if (containsRewards)
        Center(
          child: Text(
            getGoalDetails('title'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              fontStyle: FontStyle.italic,
              color: Colors.black,
            ),
          ),
        ),
      if (containsRewards)
        Center(
          child: Text(
            getGoalDetails('period'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: greyColor,
            ),
          ),
        ),
      if (containsRewards && containsTypes)
        twoColumnGreyCards(todayScoreIndicator, totalScoreIndicator),
      if (_canDebug)
        greyCard(Column(
          children: [
            Text('Last: ${lastGoal.title} (${lastGoal.rewardId})'),
            Text('${currentGoal.title} (${currentGoal.rewardId})'),
            Text('Goal Start Count: ${getGoalStartDayCount()}'),
            Text('Goal End Count: ${getGoalEndDayCount()}'),
            Text('Total Activities: $totalActivities'),
            Text('Maximum Score for the day: $maximumTotalScore'),
            Text('Actual Score for the day: $actualTotalScore'),
          ],
        )),
      if (containsRewards && containsTypes && predictReward != '')
        Center(
          child: Text(
            predictReward,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: rewardColor,
            ),
          ),
        ),
      if (!containsRewards)
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

  void setGoalPicturePath(RewardsModel rewardDetails) {
    if (rewardDetails.rewardPicture != '') {
      _goalPicture = rewardDetails.rewardPicture!;
    }
  }

  bool isTodayActivityExist() {
    DateTime today = DateTime.now();
    String todayActivityId = 'activity_${today.year}${today.month}${today.day}';
    return activityBox.containsKey(todayActivityId);
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
      Activity todayActivity = activityBox.get(activityId);
      if (todayActivity.activityItems.isNotEmpty) {
        canCreateNewActivity = false;
        Iterable<ActivityItem> todayNonEmptyActivityItems =
            todayActivity.activityItems.where((element) => element.score != '');
        if (todayNonEmptyActivityItems.isNotEmpty) {}
      }
    }

    Map<String, dynamic> scoreDetails = getScoreDetails();
    todayScore = scoreDetails['todayScore'];

    dynamic rewardScore = scoreDetails['totalScore'];
    predictReward = findGoalPrize(rewardScore);

    // TODO: Need a better reusable function to generate prize and message.
    if (rewardScore > 0) {
      totalScore = rewardScore.toString();

      if (rewardBoxMap.isNotEmpty) {
        // TODO: Fix to get iterated / active Reward details instead of first one.
        RewardsModel rewardDetails = rewardBoxMap.values.last;
        setGoalPicturePath(rewardDetails);
      }
    }

    if(isGoalEndedYesterday() || isGoalEndedMoreThanADay() || isGoalStartInFuture()) {
      _isGoalEnded = true;
      canCreateNewActivity = false;
    }

    if (canCreateNewActivity) {
      RewardsModel rewardDetails = rewardBoxMap.values.last;
      String rewardId = rewardDetails.rewardId?.toString() ?? '';

      final activityTypeKeys = activityTypeBox.keys;
      final List<ActivityItem> activityItems = [];
      for (var activityTypeKey in activityTypeKeys) {
        ActivityItem newActivityItem = ActivityItem(activityTypeKey, '');
        activityItems.add(newActivityItem);
      }
      Activity newActivity =
          Activity(activityId, activityItems, '', DateTime.now(), rewardId);
      activityBox.put(activityId, newActivity);
      showToastMessage(context, 'Today Activity created');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // set up the notification permissions class
    // set up the future to fetch the notification data
    permissionStatusFuture = getCheckNotificationPermStatus();

    askCameraPermission();
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
      setState(() {
        permissionStatusFuture = getCheckNotificationPermStatus();
      });
    }
  }

  Widget getFloatingButton(BuildContext context) {
    if (_isGoalEnded && !containsRewards ||
        !containsTypes ||
        activityBox.length == 0 || isGoalStartInFuture()) {
      return Container();
    }

    return FloatingActionButton(
      onPressed: () {
        if (isTodayActivityExist()) {
          goToUpdateActivityScreen(context);
          return;
        }
        goToGoalsForm(context);
      },
      backgroundColor: Colors.green,
      child: Icon(isTodayActivityExist() ? Icons.edit : Icons.add),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> homePanes = getHomeBlocks('100');

    return WillPopScope(
      child: Scaffold(
        appBar: customAppBar(
          title: t(context).appName,
          actions: [
            if (containsRewards && containsTypes && _isGoalEnded == false)
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
