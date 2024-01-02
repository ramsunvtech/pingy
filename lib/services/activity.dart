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

Iterable<dynamic> getActivityByCurrentGoal() {
  var rewardBox = Hive.box('rewards');
  var activityBox = Hive.box('activity');

  // TODO: Filter with latest goal period.
  if (!isRewardNotEmpty()) {
    return const Iterable.empty();
  }

  Map rewardBoxMap = rewardBox.toMap();
  RewardsModel lastReward = getLastCompletedGoal();
  Map activityBoxMap = activityBox.toMap();
  Iterable filteredActivity = activityBoxMap.values
      .where((element) => element.goalId == lastReward.rewardId);
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

  Map activityBoxMap = activityBox.toMap();
  // TODO: Filter with latest goal period.
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
        bool activityContainsScore = (currentDayScoreValue != '');

        if (isTodayActivity && activityContainsScore && isGoalEnded) {
          todayScore = currentDayScoreValue.toString();
          todayScoreTotalValue = getCurrentDayScore(activity.activityItems);
        } else if (isTodayActivity == false && activityContainsScore) {
          totalActivityScore += currentDayScoreValue;
        }
      }
    }
  }

  dynamic totalActivityDays =
      (activityBoxMapValues.isNotEmpty) ? activityBoxMapValues.length : 0;
  dynamic decidingScoreForReward = 0;

  if (totalActivityScore > 0 && totalActivityDays > 0) {
    // TODO - this days multiplies by 100, so need formatting.
    decidingScoreForReward =
        ((totalActivityScore / (100 * totalActivityDays)) * 100).ceil();
  }

  Map<String, dynamic> scoreDetails = {
    'todayScore': todayScore,
    'todayDate': getTodayDate().toString(),
    'totalScore': decidingScoreForReward,
    // others.
    'totalActivities': activityBoxMapValues.length.toString(),
    'totalActivityDays': totalActivityDays.toString(),
    'totalActivityScore': totalActivityScore.toString(),
    'maximumTotalScore': getActivitiesTotalMaximumScore().toString(),
    'actualTotalScore': todayScoreTotalValue.toString(),
  };

  return scoreDetails;
}
