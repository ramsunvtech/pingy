import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pingy/models/hive/activity.dart';
import 'package:pingy/models/hive/activity_type.dart';
import 'package:pingy/utils/navigators.dart';

import 'package:pingy/widgets/icons/settings.dart';
import 'package:pingy/widgets/SettingsBottomNavigation.dart';
import 'package:pingy/widgets/CustomAppBar.dart';

import 'package:pingy/models/hive/rewards.dart';

class ActivityTypeListScreen extends StatefulWidget {
  @override
  _ActivityTypeListScreenState createState() => _ActivityTypeListScreenState();
}

class _ActivityTypeListScreenState extends State<ActivityTypeListScreen> {
  late final Box rewardBox;
  late final Box activityTypeBox;
  late final Box activityBox;

  String activityTypeCount = '0';

  @override
  void initState() {
    super.initState();
    // Get reference to an already opened box
    rewardBox = Hive.box('rewards');
    activityBox = Hive.box('activity');
    activityTypeBox = Hive.box('activity_type');

    if (activityTypeBox.isNotEmpty) {
      activityTypeCount = activityTypeBox.length.toString();
    }
  }

  Widget getListTileTrailingIconButton(String activityTypeId) {
    return IconButton(
      onPressed: () {
        goToActivityTypeEditScreen(context, activityTypeId);
      },
      icon: const Icon(
        Icons.edit,
        color: Colors.red,
      ),
    );
  }

  int getActivitiesCountByGoalId() {
    Map rewardBoxMap = rewardBox.toMap();

    if (rewardBoxMap.isEmpty) return 0;
    RewardsModel rewardDetails = rewardBoxMap.values.last;
    String rewardId = rewardDetails?.rewardId?.toString() ?? '';

    if (rewardId.isEmpty) return 0;

    Map activityBoxMap = activityBox.toMap();
    if (activityBoxMap.isNotEmpty) {
      Iterable<dynamic> activitiesByGoalId =
          activityBoxMap.values.where((element) => element.goalId == rewardId);
      return activitiesByGoalId.length;
    }

    return 0;
  }

  int getGoalEndDayCount() {
    Map rewardBoxMap = rewardBox.toMap();

    if (rewardBoxMap.isEmpty) return 0;
    RewardsModel rewardDetails = rewardBoxMap.values.last;
    DateTime today = DateTime.now();
    List endPeriod = rewardDetails.endPeriod.split('/').toList();

    // Example: Date 2023-04-07
    String endDateString = '${endPeriod[2]}-${endPeriod[1]}-${endPeriod[0]}';
    DateTime endDate = DateTime.parse(endDateString);
    Duration diff = endDate.difference(today);
    return diff.inDays;
  }

  Widget getFloatingActionButton() {
    if (activityBox.isNotEmpty &&
        getGoalEndDayCount() > -1 &&
        getActivitiesCountByGoalId() > 0) {
      return Container();
    }

    return FloatingActionButton(
      onPressed: () {
        goToActivityTypeFormScreen(context);
      },
      backgroundColor: Colors.lightGreen,
      child: const Icon(Icons.add),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: true,
        child: Scaffold(
          appBar: customAppBar(
            title: 'Activities ($activityTypeCount)',
            actions: [
              settingsLinkIconButton(context),
            ],
          ),
          body: ValueListenableBuilder(
            valueListenable: activityTypeBox.listenable(),
            builder: (context, Box box, widget) {
              if (box.isEmpty) {
                return const Center(
                  child: Text('Add your first Activity Type and have Fun!'),
                );
              } else {
                var activityTypeList = activityTypeBox.values.toList();
                activityTypeList.sort((a, b) {
                  if (a.rank == null || a.rank.isEmpty) {
                    return 1; // put empty/null values at the end
                  } else if (b.rank == null || b.rank.isEmpty) {
                    return -1; // put empty/null values at the end
                  }

                  return a.rank.compareTo(b.rank);
                });

                return ListView.builder(
                  itemCount: activityTypeList.length,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    var currentBox = activityTypeList;
                    ActivityTypeModel activityTypeData =
                        currentBox.elementAt(index)!;

                    return InkWell(
                      onTap: () => {},
                      child: ListTile(
                        title: Text(activityTypeData.activityName),
                        subtitle: Text(activityTypeData.fullScore),
                        trailing: getListTileTrailingIconButton(
                            activityTypeData.activityTypeId),
                      ),
                    );
                  },
                );
              }
            },
          ),
          floatingActionButton: getFloatingActionButton(),
          bottomNavigationBar: settingsBottomNavigationBar(context),
        ),
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          // If the system already handled the pop, do nothing
          if (didPop) return;
          goToSettingScreen(context);
          return;
        });
  }
}
