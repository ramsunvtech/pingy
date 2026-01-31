import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pingy/services/notification.dart';

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

import 'package:flutter/foundation.dart' show kIsWeb;

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
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

  Uint8List? _goalPictureBytes;
  String _goalPicture = '';
  String? _lastCheckedActivityId;
  String? _currentLoadedGoalId;

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
  RewardsModel? getActiveGoal() {
    if (goal_service.hasNoGoalInProgress()) {
      return null;
    }
    return goal_service.getCurrentGoal();
  }

  RewardsModel? getLastCompletedGoal() {
    if (rewardBox.isEmpty) return null;
    final today = normalize(DateTime.now());
    RewardsModel? lastCompleted;
    DateTime? lastEndDate;
    for (final goal in rewardBox.values.cast<RewardsModel>()) {
      try {
        final endDate = normalize(parseDate(goal.endPeriod));
        if (endDate.isBefore(today)) {
          if (lastEndDate == null || endDate.isAfter(lastEndDate)) {
            lastEndDate = endDate;
            lastCompleted = goal;
          }
        }
      } catch (e) {
        debugPrint('Error parsing goal dates: $e');
      }
    }
    return lastCompleted;
  }

  RewardsModel? getDisplayGoal() {
    final activeGoal = getActiveGoal();
    if (activeGoal != null) return activeGoal;
    if (isGoalStartInFuture()) {
      final futureGoal = goal_service.getCurrentGoal();
      if (futureGoal != null) return futureGoal;
    }
    return getLastCompletedGoal();
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

    if (source == null) return;

    final picked = await goalPicturePicker.pickImage(
      source: source,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 85,
    );

    if (picked == null) return;

    final goal = getDisplayGoal();
    if (goal == null) return;

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

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _goalPictureBytes = bytes;
        _goalPicture = 'web_image_${DateTime.now().millisecondsSinceEpoch}';
      });
    } else {
      setState(() {
        _goalPicture = picked.path;
      });
    }
  }

  Widget getSelectedImage() {
    if (_goalPicture.isNotEmpty) {
      if (kIsWeb) {
        if (_goalPictureBytes != null && _goalPictureBytes!.isNotEmpty) {
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
              backgroundImage: MemoryImage(_goalPictureBytes!),
            ),
          );
        }
        return CircleAvatar(
          radius: 105,
          backgroundColor: Colors.white,
          child: Icon(Icons.image, size: 70, color: greyColor),
        );
      }

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
    final goal = getDisplayGoal();
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

  String _getGoalStartMessage() {
    final goal = getDisplayGoal();
    if (goal == null) return '🎯 Goal starts soon!';

    try {
      final startDate = normalize(parseDate(goal.startPeriod));
      final today = normalize(DateTime.now());
      final daysUntil = startDate.difference(today).inDays;

      if (daysUntil == 0) {
        return '🎯 Goal starts today!';
      } else if (daysUntil == 1) {
        return '🎯 Goal starts tomorrow!';
      } else if (daysUntil > 1) {
        return '🎯 Goal starts in $daysUntil days!';
      } else {
        return '🎯 Goal is active!';
      }
    } catch (e) {
      debugPrint('Error calculating goal start: $e');
      return '🎯 Goal starts soon!';
    }
  }

  String _getGoalStartSubtitle() {
    final goal = getDisplayGoal();
    if (goal == null) return 'Get ready to track your progress';

    try {
      final startDate = normalize(parseDate(goal.startPeriod));
      final today = normalize(DateTime.now());
      final daysUntil = startDate.difference(today).inDays;

      if (daysUntil == 0) {
        return 'You can start tracking now!';
      } else if (daysUntil == 1) {
        return 'Get ready to track your progress';
      } else if (daysUntil <= 7) {
        return 'Mark your calendar and prepare!';
      } else {
        return 'Plenty of time to get organized';
      }
    } catch (e) {
      return 'Get ready to track your progress';
    }
  }

  Future<void> setGoalPicturePath(RewardsModel rewardDetails) async {
    if (_currentLoadedGoalId == rewardDetails.rewardId &&
        _goalPicture == rewardDetails.rewardPicture) {
      return;
    }

    if (rewardDetails.rewardPicture != null &&
        rewardDetails.rewardPicture!.isNotEmpty) {
      setState(() {
        _goalPicture = rewardDetails.rewardPicture!;
        _currentLoadedGoalId = rewardDetails.rewardId;
      });

      if (kIsWeb) {
        try {
          final file = File(rewardDetails.rewardPicture!);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            if (mounted) {
              setState(() {
                _goalPictureBytes = bytes;
              });
            }
          }
        } catch (e) {
          debugPrint('Could not load goal picture bytes: $e');
        }
      }
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
    final goalStartsTomorrow = isGoalStartInFuture();

    String totalLabel = 'Goal Score';
    String todayScoreDisplay = '0';
    bool showTodayScore = false;

    if (hasActiveGoal) {
      todayScoreDisplay = todayScoreValue;
      showTodayScore = true;

      if (isGoalLastDay()) {
        totalLabel = 'Final Score (Today!)';
      } else {
        totalLabel = 'Goal Score';
      }
    } else if (goal_service.isGoalEndedYesterday()) {
      todayScoreDisplay = '0';
      totalLabel = 'Final Score';
      showTodayScore = false;
    } else if (goal_service.isGoalEndedMoreThanADay()) {
      todayScoreDisplay = '0';
      totalLabel = 'Your Last Score';
      showTodayScore = false;
    } else if (goalStartsTomorrow) {
      todayScoreDisplay = '0';
      totalLabel = 'Goal Score';
      showTodayScore = false;
    } else {
      todayScoreDisplay = '0';
      totalLabel = 'Goal Score';
      showTodayScore = false;
    }

    totalScore = totalScoreValue;
    todayScore = todayScoreDisplay;

    if (totalScoreInt > 0) {
      predictReward = goal_service.findGoalPrize(totalScoreInt);
    } else {
      predictReward = '';
    }

    final List<Widget> homePanes = [
      if (containsRewards && containsTypes)
        Center(
          child: GestureDetector(
            onTap: (hasActiveGoal || goalStartsTomorrow) ? getGoalImage : null,
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
      if (containsRewards && containsTypes && goalStartsTomorrow)
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              children: [
                Text(
                  _getGoalStartMessage(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: purpleColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getGoalStartSubtitle(),
                  style: TextStyle(
                    fontSize: 14,
                    color: greyColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      if (containsRewards && containsTypes && !goalStartsTomorrow)
        showTodayScore
            ? twoColumnGreyCards(
                GestureDetector(
                  onTap: () {
                    goToUpdateActivityScreen(context);
                  },
                  child: percentageIndicator(50.0, todayScore, 'Today Score'),
                ),
                GestureDetector(
                  onTap: () {
                    goToGoalStatusScreen(context);
                  },
                  child: percentageIndicator(70.0, totalScore, totalLabel),
                ),
              )
            : Center(
                child: GestureDetector(
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

    final displayGoal = getDisplayGoal();
    _isGoalEnded = isGoalEnded();

    if (displayGoal != null) {
      await setGoalPicturePath(displayGoal);
    }

    final activeGoal = getActiveGoal();
    if (activeGoal != null &&
        !_isGoalEnded &&
        containsRewards &&
        containsTypes) {
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
          setState(() {});
          showToastMessage(context, 'Today Activity created, Update Scores!');
        }
      }
    }
  }

  // --------------------------------------------------
  // FAB
  // --------------------------------------------------
  Widget getFloatingButton(BuildContext context) {
    if (!containsRewards || !containsTypes) {
      return Container();
    }

    if (isGoalStartInFuture()) {
      return Container();
    }

    final hasTodayActivity = isTodayActivityExist();

    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: FloatingActionButton(
        backgroundColor: Colors.lightGreen,
        onPressed: () {
          if (hasTodayActivity) {
            goToUpdateActivityScreen(context);
          } else {
            goToGoalsForm(context);
          }
        },
        child: Icon(_isGoalEnded ? Icons.add : Icons.edit),
      ),
    );
  }

  Widget buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.purple.shade50,
            Colors.white,
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.emoji_events,
                  size: 80,
                  color: Colors.purple.shade600,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Welcome to Steppy! 🎯',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Track your daily activities and earn amazing rewards!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _buildStepCard(
                step: '1',
                icon: Icons.flag,
                title: 'Set Your Goal',
                description:
                    'Define what you want to achieve and the rewards you\'ll earn',
                isCompleted: containsRewards,
                onTap: () => goToGoalsForm(context),
                buttonText: containsRewards ? 'Edit Goal' : 'Create Goal',
              ),
              const SizedBox(height: 16),
              _buildStepCard(
                step: '2',
                icon: Icons.checklist,
                title: 'Add Activity Types',
                description:
                    'Set up daily activities you want to track (e.g., exercise, reading)',
                isCompleted: containsTypes,
                onTap: containsRewards
                    ? () async {
                        goToActivityTypeFormScreen(context);
                        setState(() {});
                      }
                    : null,
                buttonText:
                    containsTypes ? 'Manage Activities' : 'Add Activities',
                isLocked: !containsRewards,
              ),
              const SizedBox(height: 16),
              _buildStepCard(
                step: '3',
                icon: Icons.stars,
                title: 'Track Daily Progress',
                description:
                    'Update your scores each day and watch your progress grow!',
                isCompleted: false,
                onTap: null,
                buttonText: 'Coming Soon',
                isLocked: !containsRewards || !containsTypes,
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.format_quote,
                      color: Colors.purple.shade400,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '"Success is the sum of small efforts repeated day in and day out"',
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.purple.shade700,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required String step,
    required IconData icon,
    required String title,
    required String description,
    required bool isCompleted,
    required VoidCallback? onTap,
    required String buttonText,
    bool isLocked = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isCompleted
              ? Colors.green.shade300
              : isLocked
                  ? Colors.grey.shade300
                  : Colors.purple.shade200,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLocked ? null : onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green.shade400
                            : isLocked
                                ? Colors.grey.shade300
                                : Colors.purple.shade400,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 24)
                            : Text(
                                step,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green.shade50
                            : isLocked
                                ? Colors.grey.shade100
                                : Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isLocked ? Icons.lock_outline : icon,
                        color: isCompleted
                            ? Colors.green.shade600
                            : isLocked
                                ? Colors.grey.shade500
                                : Colors.purple.shade600,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Done',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isLocked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Locked',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isLocked ? Colors.grey.shade600 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        isLocked ? Colors.grey.shade500 : Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLocked ? null : onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCompleted
                          ? Colors.green.shade400
                          : isLocked
                              ? Colors.grey.shade300
                              : Colors.purple.shade500,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: isLocked ? 0 : 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          buttonText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (!isLocked && onTap != null) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 20),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
    _updateScores();
    _updateOngoingNotification();
  }

  Future<void> _updateOngoingNotification() async {
    try {
      final scoreDetails = getScoreDetails();
      final activeGoal = getActiveGoalForActivities();

      if (activeGoal != null) {
        await NotificationService.showOngoingProgress(
          todayScore: scoreDetails['todayScore']?.toString() ?? '0',
          totalScore: scoreDetails['totalScore']?.toString() ?? '0',
          goalTitle: activeGoal.title,
        );
      } else {
        // No active goal - hide the notification
        await NotificationService.hideOngoingProgress();
      }
    } catch (e) {
      print('Error updating ongoing notification: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      _updateOngoingNotification();

      final currentActivityId = getTodayActivityId();
      if (_lastCheckedActivityId != currentActivityId) {
        await _updateScores();
      }

      setState(() {
        rewardBox = Hive.box('rewards');
        activityBox = Hive.box('activity');
        activityTypeBox = Hive.box('activity_type');
        containsRewards = rewardBox.isNotEmpty;
        containsTypes = activityTypeBox.isNotEmpty;
        permissionStatusFuture = getCheckNotificationPermStatus();
      });

      final displayGoal = getDisplayGoal();
      if (displayGoal != null) {
        await setGoalPicturePath(displayGoal);
      }
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
            rewardBox = Hive.box('rewards');
            activityBox = Hive.box('activity');
            activityTypeBox = Hive.box('activity_type');
            containsRewards = rewardBox.isNotEmpty;
            containsTypes = activityTypeBox.isNotEmpty;

            if (containsRewards) {
              final displayGoal = getDisplayGoal();
              if (displayGoal != null &&
                  _currentLoadedGoalId != displayGoal.rewardId) {
                setGoalPicturePath(displayGoal);
              }
            }

            if (!containsRewards || !containsTypes) {
              return Scaffold(
                appBar: customAppBar(
                  title: 'Steppy',
                  actions: [settingsLinkIconButton(context)],
                ),
                body: buildEmptyState(),
              );
            }

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
          }),
    );
  }
}
