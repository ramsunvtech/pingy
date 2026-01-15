import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';

// Widgets
import 'package:pingy/widgets/icons/settings.dart';
import 'package:pingy/widgets/FutureWidgets.dart';
import 'package:pingy/widgets/PercentageIndicator.dart';
import 'package:pingy/widgets/GreyCard.dart';
import 'package:pingy/widgets/CustomAppBar.dart';

// Models
import 'package:pingy/models/hive/activity.dart';
import 'package:pingy/models/hive/activity_item.dart';
import 'package:pingy/models/hive/rewards.dart';

// Utils
import 'package:pingy/utils/navigators.dart';
import 'package:pingy/utils/color.dart';
import 'package:pingy/utils/permissions.dart';

// Services
import 'package:pingy/services/goals.dart' as goal_service;
import 'package:pingy/services/activity.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final ImagePicker goalPicturePicker = ImagePicker();

  late Box rewardBox;
  late Box activityBox;
  late Box activityTypeBox;

  late Future<String> permissionStatusFuture;

  bool containsRewards = false;
  bool containsTypes = false;
  bool _isGoalEnded = false;

  String todayScore = '0';
  String totalScore = '0';
  String predictReward = '';

  String _goalPicture = '';
  String? _lastCheckedActivityId;

  // --------------------------------------------------
  // DATE HELPERS
  // --------------------------------------------------
  DateTime normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime parseDate(String date) {
    try {
      // Expected format: dd/MM/yyyy
      final parts = date.split('/');
      if (parts.length != 3) {
        throw FormatException('Invalid date format', date);
      }

      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      return DateTime(year, month, day);
    } catch (e) {
      debugPrint('Steppy Error parsing date: $e for date: $date');
      rethrow;
    }
  }

  // bool isGoalActive(RewardsModel goal) {
  //   final today = normalize(DateTime.now());
  //   final start = normalize(parseDate(goal.startPeriod));
  //   final end = normalize(parseDate(goal.endPeriod));

  //   // Goal is active if today is between start and end (inclusive)
  //   return !today.isBefore(start) && !today.isAfter(end);
  // }

  // bool isGoalEnded(RewardsModel goal) {
  //   final today = normalize(DateTime.now());
  //   final end = normalize(parseDate(goal.endPeriod));
  //   return today.isAfter(end);
  // }

  // bool isGoalStartInFuture(RewardsModel goal) {
  //   final today = normalize(DateTime.now());
  //   final start = normalize(parseDate(goal.startPeriod));
  //   return today.isBefore(start);
  // }

  bool isGoalActive() {
    return goal_service.isGoalInProgress();
  }

  bool isGoalEnded() {
    return goal_service.hasNoGoalInProgress();
  }

  bool isGoalStartInFuture() {
    return goal_service.isGoalStartInFuture();
  }

  bool isGoalLastDay() {
    return goal_service.isGoalLastDay();
  }

  // --------------------------------------------------
  // GOAL HELPERS
  // --------------------------------------------------
  // RewardsModel? getActiveGoal() {
  //   if (rewardBox.isEmpty) return null;

  //   for (final goal in rewardBox.values.cast<RewardsModel>()) {
  //     if (isGoalActive(goal)) {
  //       return goal;
  //     }
  //   }
  //   return null;
  // }
  RewardsModel? getActiveGoal() {
    if (goal_service.hasNoGoalInProgress()) {
      return null;
    }
    return goal_service.getCurrentGoal();
  }

  // RewardsModel? getLastCompletedGoal() {
  //   if (rewardBox.isEmpty) return null;

  //   // Return the last goal in the box (most recent)
  //   return rewardBox.values.last as RewardsModel;
  // }
  RewardsModel? getLastCompletedGoal() {
    return goal_service.getLastCompletedGoal();
  }

  // --------------------------------------------------
  // IMAGE
  // --------------------------------------------------
  Future<void> getGoalImage() async {
    // Show bottom sheet to choose source
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.photo_library, color: purpleColor),
                  title: Text('Choose from Gallery'),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
                ListTile(
                  leading: Icon(Icons.photo_camera, color: purpleColor),
                  title: Text('Take a Photo'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return; // User cancelled

    final picked = await goalPicturePicker.pickImage(
      source: source,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 85,
    );

    if (picked == null) return;

    final goal = getActiveGoal();
    if (goal == null) return;

    // Find the index of the active goal
    final goalsList = rewardBox.values.toList().cast<RewardsModel>();
    final goalIndex = goalsList.indexWhere((g) => g.rewardId == goal.rewardId);

    if (goalIndex == -1) return;

    final editedGoal = RewardsModel(
      goal.title,
      goal.startPeriod,
      goal.endPeriod,
      goal.firstPrice,
      goal.secondPrice,
      goal.thirdPrice,
      picked.path,
      goal.rewardId,
      '',
    );

    rewardBox.putAt(goalIndex, editedGoal);

    setState(() {
      _goalPicture = picked.path;
    });
  }

  Widget getSelectedImage() {
    if (_goalPicture.isNotEmpty) {
      final file = File(_goalPicture);
      if (file.existsSync()) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 105,
            backgroundImage: FileImage(file),
          ),
        );
      }
    }

    return CircleAvatar(
      radius: 110,
      backgroundColor: greyColor,
      child: Icon(Icons.photo_library, size: 70, color: darkGreyColor),
    );
  }

  // --------------------------------------------------
  // DISPLAY HELPERS
  // --------------------------------------------------
  String getGoalDetails(String field) {
    final goal = getActiveGoal() ?? getLastCompletedGoal();
    if (goal == null) return '';

    switch (field) {
      case 'title':
        return goal.title;
      case 'period':
        return '${goal.startPeriod} to ${goal.endPeriod}';
      default:
        return '';
    }
  }

  void setGoalPicturePath(RewardsModel rewardDetails) {
    if (rewardDetails.rewardPicture != null &&
        rewardDetails.rewardPicture!.isNotEmpty) {
      _goalPicture = rewardDetails.rewardPicture!;
    }
  }

  List<Widget> getHomeBlocks(String score) {
    final scoreDetails = getScoreDetails();

    final todayScoreValue =
        (scoreDetails['todayScore']?.toString() ?? '0').isEmpty
            ? '0'
            : scoreDetails['todayScore'].toString();
    final totalScoreValue = scoreDetails['totalScore']?.toString() ?? '0';
    final totalScoreInt = scoreDetails['totalScore'] as int? ?? 0;

    final activeGoal = getActiveGoal();
    final hasActiveGoal = activeGoal != null && !isGoalEnded();

    // Determine labels based on goal state
    String totalLabel = 'Goal Score';
    String todayScoreDisplay = '0';

    if (hasActiveGoal) {
      // Active goal in progress
      todayScoreDisplay = todayScoreValue;

      if (isGoalLastDay()) {
        totalLabel = 'Final Score (Today!)';
      } else {
        totalLabel = 'Goal Score';
      }
    } else if (goal_service.isGoalEndedYesterday()) {
      // Goal ended yesterday - show yesterday's final score
      todayScoreDisplay = '0';
      totalLabel = 'Final Score';
    } else if (goal_service.isGoalEndedMoreThanADay()) {
      // Goal ended more than a day ago
      todayScoreDisplay = '0';
      totalLabel = 'Your Last Score';
    } else {
      // No goal yet or waiting to start
      todayScoreDisplay = '0';
      totalLabel = 'Goal Score';
    }

    totalScore = totalScoreValue;
    todayScore = todayScoreDisplay;

    // Calculate predicted/actual reward
    if (totalScoreInt > 0) {
      predictReward = goal_service.findGoalPrize(totalScoreInt);
    } else {
      predictReward = '';
    }

    final List<Widget> homePanes = [
      if (containsRewards && containsTypes)
        Center(
          child: GestureDetector(
            onTap: hasActiveGoal ? getGoalImage : null,
            child: getSelectedImage(),
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
        twoColumnGreyCards(
          hasActiveGoal
              ? GestureDetector(
                  onTap: () {
                    goToUpdateActivityScreen(context);
                  },
                  child: percentageIndicator(50.0, todayScore, 'Today Score'),
                )
              : const SizedBox.shrink(),
          GestureDetector(
            onTap: () {
              goToGoalStatusScreen(context);
            },
            child: percentageIndicator(70.0, totalScore, totalLabel),
          ),
        ),
      if (containsRewards && containsTypes && predictReward.isNotEmpty)
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
          child: const Text('Add your Goal details'),
        ),
      if (containsRewards && !containsTypes)
        ElevatedButton(
          onPressed: () {
            goToActivityTypeFormScreen(context);
          },
          child: const Text('Add your Activity Types'),
        ),
    ];

    return homePanes;
  }

  // --------------------------------------------------
  // ACTIVITY
  // --------------------------------------------------
  String getTodayActivityId() {
    final t = DateTime.now();
    // Match your existing format: activity_202618 (no padding)
    return 'activity_${t.year}${t.month}${t.day}';
  }

  bool isTodayActivityExist() {
    final activityId = getTodayActivityId();
    debugPrint('🔍 Checking for activity: $activityId');
    debugPrint('🔍 Activity exists: ${activityBox.containsKey(activityId)}');
    return activityBox.containsKey(activityId);
  }

  Future<void> _updateScores() async {
    rewardBox = Hive.box('rewards');
    activityBox = Hive.box('activity');
    activityTypeBox = Hive.box('activity_type');

    containsRewards = rewardBox.isNotEmpty;
    containsTypes = activityTypeBox.isNotEmpty;

    final activeGoal = getActiveGoal();

    // Set goal ended status using service method
    _isGoalEnded = isGoalEnded();

    // Only create/update activity if there's an active goal
    if (activeGoal != null &&
        !_isGoalEnded &&
        containsRewards &&
        containsTypes) {
      // Load goal picture if available
      if (_goalPicture.isEmpty) {
        setGoalPicturePath(activeGoal);
      }

      final activityId = getTodayActivityId();
      _lastCheckedActivityId = activityId;

      if (!activityBox.containsKey(activityId)) {
        final items = activityTypeBox.keys
            .map((k) => ActivityItem(k.toString(), ''))
            .toList();

        final activity = Activity(
          activityId,
          items,
          '',
          DateTime.now(),
          activeGoal.rewardId ?? '',
        );

        await activityBox.put(activityId, activity);
        if (mounted) {
          setState(() {}); // Trigger UI rebuild
          showToastMessage(context, 'Today Activity created');
        }
      }
    }
  }

  // --------------------------------------------------
  // FAB
  // --------------------------------------------------
  Widget getFloatingButton(BuildContext context) {
    // Don't show FAB if prerequisites aren't met
    if (!containsRewards || !containsTypes) {
      return Container();
    }

    final activeGoal = getActiveGoal();

    // Don't show FAB if no active goal or goal hasn't started yet
    if (activeGoal == null || isGoalStartInFuture()) {
      return Container();
    }

    // Don't show FAB if goal has ended
    if (_isGoalEnded) {
      return Container();
    }

    final hasTodayActivity = isTodayActivityExist();

    return Padding(
      padding: const EdgeInsets.only(top: 70),
      child: FloatingActionButton(
        backgroundColor: Colors.lightGreen,
        onPressed: () {
          if (hasTodayActivity) {
            goToUpdateActivityScreen(context);
          } else {
            goToGoalsForm(context);
          }
        },
        child: Icon(hasTodayActivity ? Icons.edit : Icons.add),
      ),
    );
  }

  // --------------------------------------------------
  // LIFECYCLE
  // --------------------------------------------------
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    permissionStatusFuture = getCheckNotificationPermStatus();
    // askCameraPermission();
    _updateScores();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check when app comes to foreground
      final currentActivityId = getTodayActivityId();
      if (_lastCheckedActivityId != currentActivityId) {
        _updateScores();
      }
      setState(() {
        permissionStatusFuture = getCheckNotificationPermStatus();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Exit app when back pressed on home screen
        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
        return false;
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([
          Hive.box('rewards').listenable(),
          Hive.box('activity').listenable(),
          Hive.box('activity_type').listenable(),
        ]),
        builder: (context, _) {
          final homePanes = getHomeBlocks('100');

          return Scaffold(
            appBar: customAppBar(
              title: 'Steppy',
              actions: [settingsLinkIconButton(context)],
            ),
            body: ListView.builder(
              itemCount: homePanes.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.all(8),
                child: homePanes[i],
              ),
            ),
            floatingActionButton: getFloatingButton(context),
          );
        },
      ),
    );
  }
}
