import 'package:hive/hive.dart';

part 'rewards.g.dart';

@HiveType(typeId: 2)
class RewardsModel extends HiveObject {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final String startPeriod;

  @HiveField(2)
  final String endPeriod;

  @HiveField(3)
  final String firstPrice;

  @HiveField(4)
  final String secondPrice;

  @HiveField(5)
  final String thirdPrice;

  @HiveField(6)
  final String rewardPicture;

  RewardsModel(
    this.title,
    this.startPeriod,
    this.endPeriod,
    this.firstPrice,
    this.secondPrice,
    this.thirdPrice,
    this.rewardPicture,
  );
}
