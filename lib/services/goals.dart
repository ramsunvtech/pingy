import 'package:hive/hive.dart';
import 'package:pingy/models/hive/rewards.dart';

const int firstPrize = 95;
const int secondPrize = 85;
const int thirdPrize = 75;

int getFirstPricePercentage() {
  return firstPrize;
}

int getSecondPricePercentage() {
  return secondPrize;
}

int getThirdPricePercentage() {
  return thirdPrize;
}

bool isRewardEmpty() {
  var rewardBox = Hive.box('rewards');
  return rewardBox.isEmpty;
}

bool isRewardNotEmpty() {
  var rewardBox = Hive.box('rewards');
  return rewardBox.isNotEmpty;
}

RewardsModel getCurrentGoal() {
  var rewardBox = Hive.box('rewards');
  Map rewardBoxMap = rewardBox.toMap();
  RewardsModel rewardDetails = rewardBoxMap.values.last;
  return rewardDetails;
}

RewardsModel getLastCompletedGoal() {
  var rewardBox = Hive.box('rewards');
  Map rewardBoxMap = rewardBox.toMap();
  Iterable<dynamic> rewardIterableValues = rewardBoxMap.values;
  RewardsModel rewardDetails = rewardIterableValues.last;
  int totalRewards = rewardIterableValues.length;
  if (hasNoGoalInProgress() && rewardIterableValues.isNotEmpty) {
    int findIndex = (totalRewards > 2) ? totalRewards - 1 : 0;
    rewardDetails = rewardIterableValues.elementAt(findIndex);
  }
  return rewardDetails;
}

DateTime stripTime(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}

int getGoalDayCountByPeriodType(String periodType) {
  var rewardBox = Hive.box('rewards');
  Map rewardBoxMap = rewardBox.toMap();

  if (rewardBoxMap.isEmpty) return 0;

  RewardsModel rewardDetails = rewardBoxMap.values.last;

  DateTime today = stripTime(DateTime.now());
  // TODO: change variable name.
  List endPeriod = rewardDetails.endPeriod.split('/').toList();
  if (periodType == 'start') {
    List startPeriod = rewardDetails.startPeriod.split('/').toList();
    // Example: Date 2023-04-07
    String startDateString =
        '${startPeriod[2]}-${startPeriod[1]}-${startPeriod[0]}';
    DateTime startDate = stripTime(DateTime.parse(startDateString));
    Duration diff = startDate.difference(today);
    return diff.inDays;
  }

  // Example: Date 2023-04-07
  String endDateString = '${endPeriod[2]}-${endPeriod[1]}-${endPeriod[0]}';
  DateTime endDate = stripTime(DateTime.parse(endDateString));
  Duration diff = endDate.difference(today);
  return diff.inDays;
}

int getGoalEndDayCount() {
  return getGoalDayCountByPeriodType('');
}

int getGoalStartDayCount() {
  return getGoalDayCountByPeriodType('start');
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

bool isGoalStartInFuture() {
  int goalStartDayCount = getGoalStartDayCount();
  return (goalStartDayCount > 0);
}

bool hasNoGoalInProgress() {
  return (getGoalEndDayCount() < 0 || isGoalStartInFuture());
}

bool isGoalInProgress() {
  return (getGoalEndDayCount() >= 0);
}

String getFirstPrizeMessage(prize) {
  if (isGoalLastDay()) {
    setRewardResult(prize);
    return "🎉 Congrats! You've achieved your $prize (1st prize) milestone 🥇. Time to reward yourself! Keep going strong! 💪🌟";
  } else if (isGoalEndedYesterday()) {
    return "🎉 You won $prize (1st Prize) yesterday! Well done! Start your next goal to keep the momentum.";
  } else if (isGoalEndedMoreThanADay()) {
    return "Great job on winning $prize (1st Prize)! Begin your next goal to keep consistency.";
  }

  return 'Getting there! Keep going, You are close to get $prize.';
}

String getSecondPrizeMessage(prize) {
  if (isGoalLastDay()) {
    setRewardResult(prize);
    return "🥳 Congrats! You've hit your $prize (2nd prize) milestone 🥈. Time for a reward! Keep the momentum! 🚀🌟";
  } else if (isGoalEndedYesterday()) {
    return "🥳 You won $prize (2nd Prize) yesterday! Awesome work! Start your next goal.";
  } else if (isGoalEndedMoreThanADay()) {
    return "Great job on winning $prize (2nd Prize)! Begin your next goal to focus for 1st Prize.";
  }

  return 'Getting there! Keep going, You are close to get $prize.';
}

String geThirdPrizeMessage(String prize) {
  if (isGoalLastDay()) {
    setRewardResult(prize);
    return "🎉 Congrats! You've hit your $prize (3rd prize) milestone 🏆. Time for a treat! Keep going! 💪🌟";
  } else if (isGoalEndedYesterday()) {
    return "🎉 You won $prize (3rd Prize) yesterday! Great effort! Start your next goal.";
  } else if (isGoalEndedMoreThanADay()) {
    return "Great job on winning $prize (3rd Prize)! Begin your next goal to focus for 2nd / 1st Prize.";
  }

  return 'Getting there! Keep going, You are close to get $prize.';
}

String getNoPrizeMessage(String prize) {
  if (isGoalLastDay()) {
    setRewardResult(prize);
    return "Goal complete! No prize this time 🏆, but great effort! 'Success is small efforts repeated.' - Collier";
  } else if (isGoalEndedYesterday()) {
    return "Yesterday's goal: No prize, but solid work! On to the next one 🚀";
  } else if (isGoalEndedMoreThanADay()) {
    return "Kickstart a new goal! Your previous progress was impressive. 'Great things from small things.' - Van Gogh.";
  }

  return "It's time to get back on track. 'The secret of getting ahead is starting.' - Twain. Your next milestone awaits!";
}

String setRewardResult(prize) {
  var rewardBox = Hive.box('rewards');
  Map rewardBoxMap = rewardBox.toMap();
  RewardsModel rewardDetails = rewardBoxMap.values.last;
  // rewardDetails.won = prize;
  rewardBox.put(rewardDetails.rewardId, rewardDetails);
  return '';
}

String findGoalPrize(int rewardScore) {
  if (rewardScore == 0) {
    return 'Welcome you start! Every time you update your activities, you\'re one step closer to achieving your goal.';
  }

  var rewardBox = Hive.box('rewards');

  Map rewardBoxMap = rewardBox.toMap();

  if (rewardBoxMap.isNotEmpty) {
    RewardsModel rewardDetails = rewardBoxMap.values.last;

    int firstPricePercentage = getFirstPricePercentage();
    int secondPricePercentage = getSecondPricePercentage();
    int thirdPricePercentage = getThirdPricePercentage();
    String prize = '';

    if (rewardScore >= firstPricePercentage) {
      prize = rewardDetails.firstPrice;
      return getFirstPrizeMessage(prize);
    } else if (rewardScore >= secondPricePercentage) {
      prize = rewardDetails.secondPrice;
      return getSecondPrizeMessage(prize);
    } else if (rewardScore >= thirdPricePercentage) {
      prize = rewardDetails.thirdPrice;
      return geThirdPrizeMessage(prize);
    }
  }

  return getNoPrizeMessage('No Prize for $rewardScore');
}
