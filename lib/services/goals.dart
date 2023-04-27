
import 'dart:ffi';

import 'package:hive/hive.dart';
import 'package:pingy/models/hive/rewards.dart';

int getFirstPricePercentage() {
  return 95;
}

int getSecondPricePercentage() {
  return 85;
}

int getThirdPricePercentage() {
  return 75;
}

RewardsModel getCurrentGoal() {
  var rewardBox = Hive.box('rewards');
  Map rewardBoxMap = rewardBox.toMap();
  RewardsModel rewardDetails = rewardBoxMap.values.last;
  return rewardDetails;
}

int getGoalEndDayCount() {
  var rewardBox = Hive.box('rewards');
  Map rewardBoxMap = rewardBox.toMap();

  if (rewardBoxMap.isEmpty) return 0;

  RewardsModel rewardDetails = rewardBoxMap.values.last;
  String rewardId = rewardDetails.rewardId ?? '';

  DateTime today = DateTime.now();
  List endPeriod = rewardDetails.endPeriod.split('/').toList();

  // Example: Date 2023-04-07
  String endDateString = '${endPeriod[2]}-${endPeriod[1]}-${endPeriod[0]}';
  DateTime endDate = DateTime.parse(endDateString);
  Duration diff = endDate.difference(today);
  return diff.inDays;
}

bool isGoalLastDay() {
  int goalEndDayCount = getGoalEndDayCount();
  return (goalEndDayCount == 0);
}

bool isGoalEndedYesterday() {
  int goalEndDayCount = getGoalEndDayCount();
  return (goalEndDayCount == -1);
}

bool isGoalEndedMoreThanADay() {
  int goalEndDayCount = getGoalEndDayCount();
  return (goalEndDayCount < -1);
}

String getFirstPrizeMessage(prize) {
  if (isGoalLastDay()) {
    return "Goal ends tomorrow, first milestones reached! Keep up the momentum for your next big win!";
  } else if (isGoalEndedYesterday()) {
    setRewardResult(prize);
    return "Congratulations! You've reached your $prize (1st prize) milestone and it's time to reward yourself! And  don’t stop now, keep up the momentum until the end!";
  } else if (isGoalEndedMoreThanADay()) {
    setRewardResult(prize);
    return "Great job on winning $prize (1st Prize) last time! Begin your next goal to keep consistency.";
  }

  return 'Getting there! Keep going, You are close to get $prize.';
}

String getSecondPrizeMessage(prize) {
  if (isGoalLastDay()) {
    return "Goal ends tomorrow, second milestones reached! Keep up the momentum for your next big win!";
  } else if (isGoalEndedYesterday()) {
    setRewardResult(prize);
    return "Congratulations! You've reached your $prize (2nd prize) milestone and it's time to reward yourself! And  don’t stop now, keep up the momentum until the end!";
  } else if (isGoalEndedMoreThanADay()) {
    setRewardResult(prize);
    return "Great job on winning $prize (2nd Prize) last time! Begin your next goal to focus for 1st Prize.";
  }

  return 'Getting there! Keep going, You are close to get $prize.';
}

String geThirdPrizeMessage(String prize) {
  if (isGoalLastDay()) {
    return "Goal ends tomorrow, third milestones reached! Keep up the momentum for your next big win!";
  } else if (isGoalEndedYesterday()) {
    setRewardResult(prize);
    return "Congratulations! You've reached your $prize (3rd prize) milestone and it's time to reward yourself! And  don’t stop now, keep up the momentum until the end!";
  } else if (isGoalEndedMoreThanADay()) {
    setRewardResult(prize);
    return "Great job on winning $prize (3rd Prize) last time! Begin your next goal to for focus for 2nd / 1st Prize.";
  }

  return 'Getting there! Keep going, You are close to get $prize.';
}

String getNoPrizeMessage(String prize) {
  if (isGoalLastDay()) {
    return "Goal ends tomorrow, keep going! Celebrate your progress even if you didn't reach a milestone.";
  } else if (isGoalEndedYesterday()) {
    setRewardResult(prize);
    return "Great effort! Even though you couldn't hit any milestone, keep celebrating the steps you've taken so far. You're making great strides towards your success";
  } else if (isGoalEndedMoreThanADay()) {
    setRewardResult(prize);
    return "Great job on last time! Begin your next goal to for focus on milestone prizes.";
  }

  return 'Getting there! still not late, Work hard to reach the milestone.';
}

String setRewardResult(prize) {
  var rewardBox = Hive.box('rewards');
  Map rewardBoxMap = rewardBox.toMap();
  RewardsModel rewardDetails = rewardBoxMap.values.last;
  rewardDetails.won = prize;
  rewardBox.put(rewardDetails.rewardId, rewardDetails);
  return '';
}

String findGoalPrize(int rewardScore) {
  if (rewardScore == 0) {
    return 'Welcome you Start! Every time you update your activities, you\'re one step closer to achieving your goal.';
  }

  var rewardBox = Hive.box('rewards');

  Map rewardBoxMap = rewardBox.toMap();

  if (rewardBoxMap.isNotEmpty) {
    RewardsModel rewardDetails = rewardBoxMap.values.last;

    int firstPricePercentage = getFirstPricePercentage();
    int secondPricePercentage = getSecondPricePercentage();
    int thirdPricePercentage = getThirdPricePercentage();
    String prize = '';
    String prizeType = '';

    if (rewardScore >= firstPricePercentage) {
      prizeType = '$firstPricePercentage%';
      prize = rewardDetails.firstPrice;
      return getFirstPrizeMessage(prize);
    } else if (rewardScore >= secondPricePercentage) {
      prizeType = '$secondPricePercentage%';
      prize = rewardDetails.secondPrice;
      return getSecondPrizeMessage(prize);
    } else if (rewardScore >= thirdPricePercentage) {
      prizeType = '$thirdPricePercentage%';
      prize = rewardDetails.thirdPrice;
      return geThirdPrizeMessage(prize);
    }

    return getNoPrizeMessage('No Prize for $rewardScore');
  }

  return getNoPrizeMessage('No Prize for $rewardScore');
}
