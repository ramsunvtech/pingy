import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';

// Widgets.
import 'package:pingy/widgets/icons/settings.dart';
import 'package:pingy/widgets/FutureWidgets.dart';
import 'package:pingy/widgets/PercentageIndicator.dart';
import 'package:pingy/widgets/GreyCard.dart';
import 'package:pingy/widgets/CustomAppBar.dart';

// Models.
import 'package:pingy/models/hive/activity.dart';
import 'package:pingy/models/hive/activity_item.dart';
import 'package:pingy/models/hive/rewards.dart';

// Utils.
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

  void showAlert(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget getSelectedImage() {
    if (_goalPictureSelected || _goalPicture.isNotEmpty) {
      File goalPictureFile = File(_goalPicture);
      if (goalPictureFile.existsSync()) {
        return
          Container(
            decoration: BoxDecoration(
              color: Colors.white, // Match the background color to the white background
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3), // Soft grey shadow
                  spreadRadius: 1, // Extend the shadow to all sides by 1 pixel
                  blurRadius: 5, // Soften the shadow by blurring it
                  offset: Offset(0, 3), // Position the shadow below the avatar
                ),
              ],
            ),
            child: CircleAvatar(
                radius: 110 - 5,
                backgroundImage: Image.file(
                  goalPictureFile,
                  fit: BoxFit.cover,
                ).image),
          );
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
    String todayDateValue = scoreDetails['todayDate'] ?? '0';
    String todayScoreValue = scoreDetails['todayScore'] ?? '0';
    String totalActivityDays = scoreDetails['totalActivityDays'] ?? '0';
    String totalActivityScore = scoreDetails['totalActivityScore'] ?? '0';
    String totalScoreValue = scoreDetails['totalScore'].toString() ?? '0';
    String totalActivities = scoreDetails['totalActivities'] ?? '-';
    String maximumTotalScore = scoreDetails['maximumTotalScore'] ?? '-';
    String actualTotalScore = scoreDetails['actualTotalScore'] ?? '-';
    String? currentGoalTitle = '?Title?';
    String? currentGoalRewardId = '?Id?';
    String? lastGoalTitle = '?Title?';
    String? lastGoalRewardId = '?Id?';

    if (isRewardNotEmpty()) {
      RewardsModel currentGoal = getCurrentGoal();
      currentGoalTitle = currentGoal.title;
      currentGoalRewardId = currentGoal.rewardId;
      RewardsModel lastGoal = getLastCompletedGoal();
      lastGoalTitle = lastGoal.title;
      lastGoalRewardId = lastGoal.rewardId;
    }

    bool canHideTodayPercentageIndicator = (
        isRewardEmpty() || hasNoGoalInProgress()
    );
    bool canHideTotalPercentageIndicator = (
        isRewardEmpty()
    );
    String totalPercentageIndicatorLabel ='Total Score';

    if (hasNoGoalInProgress()) {
      totalScore = totalScoreValue;
      totalPercentageIndicatorLabel = 'Your Last Score';
    }

    double indicatorRadius = 50.0;
    Widget leftSideTodayScoreIndicator = (canHideTodayPercentageIndicator)
        ? const SizedBox.shrink()
        : percentageIndicator(indicatorRadius, todayScoreValue, 'Today Score');
    Widget rightSideTotalScoreIndicator = (canHideTotalPercentageIndicator)
    ? const SizedBox.shrink()
    : percentageIndicator(70.0, totalScore,
        totalPercentageIndicatorLabel);

    // Inside a build method of a Widget
    double screenHeight = MediaQuery.of(context).size.height;
    // You can adjust the factor (0.15 in this case) to fit the circle avatar in your layout properly
    double avatarRadius = screenHeight * 0.127;

    final List<Widget> homePanes = [
      if (containsRewards && containsTypes)
        Center(
          child: GestureDetector(
            onTap: () async {
              await getGoalImage();
            },
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: avatarRadius,
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
        twoColumnGreyCards(leftSideTodayScoreIndicator, rightSideTotalScoreIndicator),
      if (_canDebug)
        greyCard(Column(
          children: [
            Text('Last: $lastGoalTitle ($lastGoalRewardId)'),
            Text('$currentGoalTitle ($currentGoalRewardId)'),
            Text('Today date: ${todayDateValue.toString()}'),
            Text('Goal Start Count: ${getGoalStartDayCount()}'),
            Text('Goal End Count: ${getGoalEndDayCount()}'),
            Text('Total Activity Days: $totalActivityDays'),
            Text('Total Activity Scores: $totalActivityScore'),
            Text('Total Activities: $totalActivities'),
            Text('Total Score: $totalScoreValue'),
            Text('Maximum Score for the day: $maximumTotalScore'),
            Text('Actual Score for the day: $actualTotalScore'),
            Text('containsRewards: $containsRewards'),
            Text('containsTypes: $containsTypes'),
            Text('predictReward: $predictReward'),
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
          // TODO: Fix localization setup as per flutter 3.16.5 from 3.7.10 changes
          // child: Text(t(context).addGoals),
          child: const Text('Add your Goal details'),
        ),
      if (containsRewards && !containsTypes)
        ElevatedButton(
          onPressed: () {
            goToActivityTypeFormScreen(context);
          },
          // TODO: Fix localization setup as per flutter 3.16.5 from 3.7.10 changes
          // child: Text(t(context).addActivityTypes),
          child: const Text('Add your Activity Types'),
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
    String activityId = getTodayActivityId();
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

    bool isTodayActivityExist = activityBox.containsKey(activityId);
    if (isTodayActivityExist) {
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

    setState(() {
      predictReward = findGoalPrize(rewardScore);
    });

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

    // Create New Activity.
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
          // TODO: Fix localization setup as per flutter 3.16.5 from 3.7.10 changes
          // title: t(context).appName,
          title: 'Steppy',
          actions: [
              // if (containsRewards && containsTypes)
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
