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
import 'package:pingy/services/goals.dart';
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
  bool _goalPictureSelected = false;

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

  bool isGoalActive(RewardsModel goal) {
    final today = normalize(DateTime.now());
    final start = normalize(parseDate(goal.startPeriod));
    final end = normalize(parseDate(goal.endPeriod));

    // Goal is active if today is between start and end (inclusive)
    return !today.isBefore(start) && !today.isAfter(end);
  }

  bool isGoalEnded(RewardsModel goal) {
    final today = normalize(DateTime.now());
    final end = normalize(parseDate(goal.endPeriod));
    return today.isAfter(end);
  }

  bool isGoalStartInFuture(RewardsModel goal) {
    final today = normalize(DateTime.now());
    final start = normalize(parseDate(goal.startPeriod));
    return today.isBefore(start);
  }

  // --------------------------------------------------
  // GOAL HELPERS
  // --------------------------------------------------
  RewardsModel? getActiveGoal() {
    if (rewardBox.isEmpty) return null;

    for (final goal in rewardBox.values.cast<RewardsModel>()) {
      if (isGoalActive(goal)) {
        return goal;
      }
    }
    return null;
  }

  RewardsModel? getLastCompletedGoal() {
    if (rewardBox.isEmpty) return null;

    // Return the last goal in the box (most recent)
    return rewardBox.values.last as RewardsModel;
  }

  // --------------------------------------------------
  // IMAGE
  // --------------------------------------------------
  Future<void> getGoalImage() async {
    final picked = await goalPicturePicker.pickImage(
      source: ImageSource.camera,
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
      _goalPictureSelected = true;
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
      child: Icon(Icons.camera_alt, size: 70, color: darkGreyColor),
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

    // Debug output
    debugPrint('=== Score Details Debug ===');
    debugPrint('scoreDetails: $scoreDetails');
    debugPrint('Active Goal: ${getActiveGoal()?.title}');
    debugPrint('Active Goal RewardId: ${getActiveGoal()?.rewardId}');
    debugPrint('Activity Box Keys: ${activityBox.keys.toList()}');
    debugPrint('Today Activity ID: ${getTodayActivityId()}');
    debugPrint('Today Activity Exists: ${isTodayActivityExist()}');

    // Check today's activity details
    if (isTodayActivityExist()) {
      final todayActivity = activityBox.get(getTodayActivityId());
      debugPrint('📋 Today Activity: $todayActivity');

      // Check if it's an Activity object with activityItems
      if (todayActivity is Activity) {
        debugPrint(
            '📋 Activity Items Count: ${todayActivity.activityItems.length}');
        for (var item in todayActivity.activityItems) {
          debugPrint('📋 Item: ${item.activityItemId} = "${item.score}"');
        }
      }
    }

    // Handle empty string scores
    final todayScoreValue =
        (scoreDetails['todayScore']?.toString() ?? '0').isEmpty
            ? '0'
            : scoreDetails['todayScore'].toString();
    final totalScoreValue = scoreDetails['totalScore']?.toString() ?? '0';
    final totalScoreInt = scoreDetails['totalScore'] as int? ?? 0;

    debugPrint(
        'Today Score Value: "$todayScoreValue" (empty: ${todayScoreValue.isEmpty})');
    debugPrint('Total Score Value: $totalScoreValue');
    debugPrint('===========================');

    final activeGoal = getActiveGoal();
    final hasActiveGoal = activeGoal != null;

    // Determine labels
    String totalLabel = 'Total Score';

    if (!hasActiveGoal) {
      // No active goal - show last completed goal's score
      if (isGoalEndedYesterday()) {
        totalLabel = 'Final Score';
      } else {
        totalLabel = 'Your Last Score';
      }
      todayScore = '0'; // No today score if no active goal
      totalScore = totalScoreValue;
    } else {
      // Active goal in progress
      todayScore = todayScoreValue;
      totalScore = totalScoreValue;
      totalLabel = 'Total Score';
    }

    // Calculate predicted reward
    if (hasActiveGoal && totalScoreInt > 0) {
      predictReward = findGoalPrize(totalScoreInt);
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

    // Set goal ended status
    if (activeGoal == null) {
      _isGoalEnded = true;
    } else {
      _isGoalEnded = isGoalEnded(activeGoal);

      // Load goal picture if available
      if (_goalPicture.isEmpty) {
        setGoalPicturePath(activeGoal);
      }
    }

    // Only create new activity if there's an active goal and prerequisites are met
    if (activeGoal != null &&
        !_isGoalEnded &&
        !isGoalStartInFuture(activeGoal) &&
        containsRewards &&
        containsTypes) {
      final activityId = getTodayActivityId();

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
        debugPrint(
            '✅ Created today activity with rewardId: ${activeGoal.rewardId}');
        if (mounted) {
          showToastMessage(context, 'Today Activity created');
        }
      } else {
        // Check if existing activity needs goalId update
        final existingActivity = activityBox.get(activityId) as Activity;

        debugPrint('📋 Existing activity goalId: ${existingActivity.goalId}');
        debugPrint('📋 Active goal rewardId: ${activeGoal.rewardId}');

        // Check if goalId needs updating
        if (existingActivity.goalId != activeGoal.rewardId) {
          debugPrint('⚠️ Activity has wrong goalId!');
          debugPrint(
              '🔧 Fixing goalId from ${existingActivity.goalId} to ${activeGoal.rewardId}...');

          // Create updated activity with correct goalId
          final updatedActivity = Activity(
            existingActivity.activityId, // activityId
            existingActivity.activityItems, // activityItems
            existingActivity.score, // score
            existingActivity.activityDate, // activityDate
            activeGoal.rewardId, // goalId (FIXED)
          );

          await activityBox.put(activityId, updatedActivity);
          debugPrint('✅ Fixed goalId to: ${activeGoal.rewardId}');

          if (mounted) {
            showToastMessage(context, 'Fixed activity link to current goal');
          }
        } else {
          debugPrint('✅ Activity goalId is correct');
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
    if (activeGoal == null || isGoalStartInFuture(activeGoal)) {
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
    askCameraPermission();
    _updateScores();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
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
