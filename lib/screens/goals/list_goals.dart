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

  bool isGoalActive(RewardsModel goal) {
    try {
      final today = DateTime.now();
      final normalizedToday = DateTime(today.year, today.month, today.day);

      final start = _parseDate(goal.startPeriod);
      final end = _parseDate(goal.endPeriod);

      return !normalizedToday.isBefore(start) && !normalizedToday.isAfter(end);
    } catch (e) {
      return false;
    }
  }

  bool isGoalEnded(RewardsModel goal) {
    try {
      final today = DateTime.now();
      final normalizedToday = DateTime(today.year, today.month, today.day);
      final end = _parseDate(goal.endPeriod);
      return normalizedToday.isAfter(end);
    } catch (e) {
      return false;
    }
  }

  DateTime _parseDate(String date) {
    final parts = date.split('/');
    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);
    return DateTime(year, month, day);
  }

  String getGoalStatusText(RewardsModel goal) {
    if (isGoalActive(goal)) {
      return 'Active';
    } else if (isGoalEnded(goal)) {
      return 'Completed';
    } else {
      return 'Upcoming';
    }
  }

  Color getGoalStatusColor(RewardsModel goal) {
    if (isGoalActive(goal)) {
      return Colors.green;
    } else if (isGoalEnded(goal)) {
      return Colors.blue;
    } else {
      return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
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
                  String statusText = getGoalStatusText(rewardsData);
                  Color statusColor = getGoalStatusColor(rewardsData);

                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      goToGoalStatusScreenWithId(
                        context,
                        rewardsData.rewardId ?? '',
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 2,
                      child: Column(
                        children: [
                          ListTile(
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    rewardsData.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: statusColor),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${rewardsData.startPeriod} to ${rewardsData.endPeriod}\n'
                                'First Prize (95%): ${getPrize(rewardsData.firstPrice)}\n'
                                'Second Prize (85%): ${getPrize(rewardsData.secondPrice)}\n'
                                'Third Prize (75%): ${getPrize(rewardsData.thirdPrice)}\n'
                                '${getGoalResult(rewardsData)}'
                                'Goal Picture: ${isPictureExist(rewardsData)}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
        floatingActionButton: getFloatingButton(context),
        bottomNavigationBar: settingsBottomNavigationBar(context),
      ),
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        // If the system already handled the pop, do nothing
        if (didPop) return;
        goToSettingScreen(context);
        return;
      },
    );
  }
}
