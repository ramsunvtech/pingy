import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pingy/models/hive/rewards.dart';
import 'package:pingy/utils/navigators.dart';

import 'package:pingy/widgets/icons/settings.dart';
import 'package:pingy/widgets/SettingsBottomNavigation.dart';
import 'package:pingy/widgets/CustomAppBar.dart';

class GoalListScreen extends StatefulWidget {
  @override
  _GoalListScreenState createState() => _GoalListScreenState();
}

class _GoalListScreenState extends State<GoalListScreen> {
  late final Box rewardsBox;

  @override
  void initState() {
    super.initState();
    // Get reference to an already opened box
    rewardsBox = Hive.box('rewards');
  }

  Widget getFloatingButton(BuildContext context) {
    if (rewardsBox.isEmpty) {
      return Container();
    } else if (rewardsBox.isNotEmpty) {
      RewardsModel latestGoal = rewardsBox.values.last;
      List endPeriod = latestGoal.endPeriod.split('/').toList();

      DateTime today = DateTime.now();
      DateTime endDate =
          DateTime.parse('${endPeriod[2]}-${endPeriod[1]}-${endPeriod[0]}');
      Duration diff = endDate.difference(today);

      if (diff.inDays > 0) {
        return Container();
      }
    }

    return FloatingActionButton(
      onPressed: () {
        goToGoalsForm(context);
      },
      backgroundColor: Colors.lightGreen,
      child: const Icon(Icons.add),
    );
  }

  String getPrize(String prize) {
    return (prize == '') ? 'Not Mentioned' : prize;
  }

  String getGoalResult(RewardsModel rewardDetails) {
    if (rewardDetails.won != '') {
      return 'Won: ${rewardDetails.won}\n';
    }

    return '';
  }

  String isPictureExist(RewardsModel rewardDetails) {
    return (rewardDetails.rewardPicture == '') ? 'No' : 'Yes';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        appBar: customAppBar(
          title: 'Goals',
          actions: [
            settingsLinkIconButton(context),
          ],
        ),
        body: ValueListenableBuilder(
          valueListenable: rewardsBox.listenable(),
          builder: (context, Box box, widget) {
            if (box.isEmpty) {
              return const Center(
                child: Text('No Goals are available.'),
              );
            } else {
              return ListView.builder(
                itemCount: rewardsBox.length,
                physics: const AlwaysScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  var currentBox = rewardsBox;
                  RewardsModel rewardsData = currentBox.getAt(index)!;
                  return InkWell(
                      onTap: () => {},
                      child: ListTile(
                        title: Text(rewardsData.title),
                        subtitle: Text(
                            '${rewardsData.startPeriod}'
                                ' to ${rewardsData.endPeriod}\n'
                                'First Prize (95%): ${getPrize(rewardsData.firstPrice)}\n'
                                'Second Prize (85%): ${getPrize(rewardsData.secondPrice)}\n'
                                'Third Prize (75%): ${getPrize(rewardsData.thirdPrice)}\n'
                                '${getGoalResult(rewardsData)}'
                                'Goal Picture: ${isPictureExist(rewardsData)}\n'
                        ),
                      ));
                },
              );
            }
          },
        ),
        floatingActionButton: getFloatingButton(context),
        bottomNavigationBar: settingsBottomNavigationBar(context),
      ),
      onWillPop: () async {
        goToSettingScreen(context);
        return true;
      },
    );
  }
}
