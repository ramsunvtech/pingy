import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pingy/models/hive/activity.dart';
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
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

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

  int getActivitiesCountByGoalId() {
    Map rewardBoxMap = rewardBox.toMap();

    if (rewardBoxMap.isEmpty) return 0;
    RewardsModel rewardDetails = rewardBoxMap.values.last;
    String rewardId = rewardDetails?.rewardId?.toString() ?? '';

    if (rewardId.isEmpty) return 0;

    Map activityBoxMap = activityBox.toMap();
    if (activityBoxMap.isNotEmpty) {
      Iterable<dynamic> activitiesByGoalId = activityBoxMap.values.where((element) => element.goalId == rewardId);
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
    if (activityBox.isNotEmpty && getGoalEndDayCount() > -1 && getActivitiesCountByGoalId() > 0) {
      return Container();
    }

    return FloatingActionButton(
      onPressed: () {
        goToActivityTypeFormScreen(context);
      },
      backgroundColor: const Color(0xFF98006D),
      child: const Icon(Icons.add),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: Scaffold(
          appBar: customAppBar(
            title: 'Activity Types ($activityTypeCount)',
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
                return RefreshIndicator(
                  key: _refreshIndicatorKey,
                  color: Colors.white,
                  backgroundColor: Colors.blue,
                  strokeWidth: 4.0,
                  onRefresh: () async {
                    // Replace this delay with the code to be executed during refresh
                    // and return a Future when code finish execution.
                    return Future<void>.delayed(const Duration(seconds: 3));
                  },
                  // Pull from top to show refresh indicator.
                  child: ListView.builder(
                    itemCount: activityTypeBox.length,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      var currentBox = activityTypeBox;
                      var activityTypeData = currentBox.getAt(index)!;
                      return InkWell(
                        onTap: () => {},
                        child: ListTile(
                          title: Text(activityTypeData.activityName),
                          subtitle: Text(activityTypeData.fullScore),
                        ),
                      );
                    },
                  ),
                );
              }
            },
          ),
          floatingActionButton: getFloatingActionButton(),
          bottomNavigationBar: settingsBottomNavigationBar(context),
        ),
        onWillPop: () async {
          goToSettingScreen(context);
          return true;
        });
  }
}
