
import 'package:hive/hive.dart';
import 'package:pingy/models/hive/rewards.dart';

String findGoalPrize(int rewardScore) {
  var rewardBox = Hive.box('rewards');

  Map rewardBoxMap = rewardBox.toMap();

  if (rewardBoxMap.isNotEmpty) {
    RewardsModel rewardDetails = rewardBoxMap.values.last;

    int firstPricePercentage = 95;
    int secondPricePercentage = 85;
    int thirdPricePercentage = 75;
    String prize = '';
    String prizeType = '';
    String comment = '';
    String greet = '';

    if (rewardScore >= firstPricePercentage) {
      comment = 'Getting there!';
      prizeType = '$firstPricePercentage%';
      prize = rewardDetails.firstPrice;
    } else if (rewardScore >= secondPricePercentage) {
      comment = 'Almost there!';
      prizeType = '$secondPricePercentage%';
      prize = rewardDetails.secondPrice;
    } else if (rewardScore >= thirdPricePercentage) {
      comment = 'You did it!';
      prizeType = '$thirdPricePercentage%';
      prize = rewardDetails.thirdPrice;
    }

    if (prize.isNotEmpty) {
      return '$comment You have achieved almost $prizeType of your Goal! You have earned the $prize Reward. Congratulations!';
    }
  }

  return '';
}