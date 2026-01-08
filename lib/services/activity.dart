import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:pingy/models/hive/activity.dart';
import 'package:pingy/models/hive/rewards.dart';

import 'goals.dart';

void l(String message, {bool verbose = false}) {
  if (verbose) {
    if (kDebugMode) {
      print(message);
    }
  }
}

DateTime getTodayDate() {
  return stripTime(DateTime.now());
}

dynamic getActivitiesTotalMaximumScore() {
  dynamic activityTypeFullScore = 0;
  var activityTypeBox = Hive.box('activity_type');

  if (activityTypeBox.isEmpty) {
    return activityTypeFullScore;
  }

  Map activityTypeBoxMap = activityTypeBox.toMap();

  activityTypeBoxMap.forEach((key, value) {
    activityTypeFullScore += int.tryParse(value.fullScore)!;
  });
  return activityTypeFullScore;
}

String getTodayActivityId() {
  var today = DateTime.now();
  return 'activity_${today.year}${today.month}${today.day}';
}

// Helper to get active goal
RewardsModel? getActiveGoalForActivities() {
  var rewardBox = Hive.box('rewards');
  if (rewardBox.isEmpty) return null;

  final today = DateTime.now();
  final normalizedToday = DateTime(today.year, today.month, today.day);

  for (final goal in rewardBox.values.cast<RewardsModel>()) {
    final start = _parseDate(goal.startPeriod);
    final end = _parseDate(goal.endPeriod);

    if (!normalizedToday.isBefore(start) && !normalizedToday.isAfter(end)) {
      return goal;
    }
  }
  
  // If no active goal, return the last goal
  return rewardBox.values.last as RewardsModel;
}

DateTime _parseDate(String date) {
  final parts = date.split('/');
  if (parts.length != 3) {
    throw FormatException('Invalid date format', date);
  }
  final day = int.parse(parts[0]);
  final month = int.parse(parts[1]);
  final year = int.parse(parts[2]);
  return DateTime(year, month, day);
}

Iterable<dynamic> getActivityByCurrentGoal() {
  var rewardBox = Hive.box('rewards');
  var activityBox = Hive.box('activity');

  if (!isRewardNotEmpty()) {
    return const Iterable.empty();
  }

  // FIX: Use active goal instead of last completed goal
  RewardsModel? currentGoal = getActiveGoalForActivities();
  
  if (currentGoal == null) {
    debugPrint('⚠️ No active goal found, using last goal');
    currentGoal = getLastCompletedGoal();
  }

  debugPrint('🎯 Filtering activities by goalId: ${currentGoal.rewardId}');

  Map activityBoxMap = activityBox.toMap();
  Iterable filteredActivity = activityBoxMap.values
      .where((element) => element.goalId == currentGoal!.rewardId);
  
  debugPrint('📊 Found ${filteredActivity.length} activities for this goal');
  
  return filteredActivity;
}

dynamic getCurrentDayScore(dynamic activityItems) {
  dynamic dayScore = 0;

  activityItems.forEach((element) {
    var scoreValue = int.tryParse(element.score ?? "0");

    if (scoreValue != null) {
      dayScore += scoreValue;
    }
  });

  return dayScore;
}

dynamic getCurrentActivityDayScore(activityItems) {
  int activityTypeFullScore = getActivitiesTotalMaximumScore();

  if (activityTypeFullScore == 0) return 0;

  int dayScore = getCurrentDayScore(activityItems);
  return (((dayScore / activityTypeFullScore) * 100).ceil());
}

Map<String, dynamic> getScoreDetails() {
  var activityBox = Hive.box('activity');
  var todayActivityId = getTodayActivityId();

  debugPrint('🔍 Getting score details for today: $todayActivityId');

  Map activityBoxMap = activityBox.toMap();
  Iterable<dynamic> activityBoxMapValues = const Iterable.empty();

  if (isRewardNotEmpty()) {
    activityBoxMapValues = getActivityByCurrentGoal();
  }

  String todayScore = '';
  dynamic currentDayScoreValue = 0;
  dynamic todayScoreTotalValue = 0;
  dynamic totalActivityScore = 0;
  bool isGoalEnded = isGoalEndedYesterday() || isGoalEndedMoreThanADay();

  if (activityBoxMapValues.isNotEmpty) {
    for (var activity in activityBoxMapValues) {
      dynamic dayScore = 0;
      if (activity.activityItems.length > 0) {
        currentDayScoreValue = getCurrentActivityDayScore(activity.activityItems);
        bool isTodayActivity = (activity.activityId == todayActivityId);
        bool activityContainsScore = (currentDayScoreValue != '' && currentDayScoreValue != 0);

        debugPrint('📅 Activity ${activity.activityId}: score=$currentDayScoreValue, isToday=$isTodayActivity');

        if (isTodayActivity && activityContainsScore) {
          todayScore = currentDayScoreValue.toString();
          todayScoreTotalValue = getCurrentDayScore(activity.activityItems);
          debugPrint('✅ Today score found: $todayScore');
        }

        if (!isTodayActivity && activityContainsScore) {
          totalActivityScore += currentDayScoreValue;
        }
      }
    }
  }

  dynamic totalActivityDays =
      (activityBoxMapValues.isNotEmpty) ? activityBoxMapValues.length : 0;

  if (isGoalEnded == false) {
    // exclude today activity
    totalActivityDays = totalActivityDays - 1;
  }

  dynamic decidingScoreForReward = 0;

  if (totalActivityScore > 0 && totalActivityDays > 0) {
    decidingScoreForReward =
        ((totalActivityScore / (100 * totalActivityDays)) * 100).ceil();
  }

  debugPrint('📊 Total activity days: $totalActivityDays');
  debugPrint('📊 Total activity score: $totalActivityScore');
  debugPrint('📊 Final reward score: $decidingScoreForReward');

  Map<String, dynamic> scoreDetails = {
    'todayScore': todayScore,
    'todayDate': getTodayDate(),
    'totalScore': decidingScoreForReward,
    // others.
    'totalActivities': activityBoxMapValues.length,
    'totalActivityDays': totalActivityDays,
    'totalActivityScore': totalActivityScore,
    'maximumTotalScore': getActivitiesTotalMaximumScore(),
    'actualTotalScore': todayScoreTotalValue,
  };

  return scoreDetails;
}