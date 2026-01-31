import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
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

  /// NEW: Check if today is the first day of the goal
  bool isFirstDayOfGoal() {
    Map rewardBoxMap = rewardBox.toMap();
    if (rewardBoxMap.isEmpty) return false;

    RewardsModel rewardDetails = rewardBoxMap.values.last;
    DateTime today = DateTime.now();
    DateTime normalizedToday = DateTime(today.year, today.month, today.day);

    List startPeriod = rewardDetails.startPeriod.split('/').toList();
    
    // Parse start date: DD/MM/YYYY
    String startDateString = '${startPeriod[2]}-${startPeriod[1]}-${startPeriod[0]}';
    DateTime startDate = DateTime.parse(startDateString);
    DateTime normalizedStartDate = DateTime(startDate.year, startDate.month, startDate.day);

    return normalizedToday.isAtSameMomentAs(normalizedStartDate);
  }

  /// UPDATED: Show FAB if:
  /// 1. No activities exist yet, OR
  /// 2. Goal has ended (negative days), OR  
  /// 3. No activities for current goal, OR
  /// 4. TODAY IS FIRST DAY OF GOAL (NEW CONDITION)
  Widget getFloatingActionButton() {
    // Show FAB if it's the first day of goal
    if (isFirstDayOfGoal()) {
      return FloatingActionButton(
        onPressed: () {
          goToActivityTypeFormScreen(context);
        },
        backgroundColor: Colors.lightGreen,
        child: const Icon(Icons.add),
      );
    }

    // Original logic: hide FAB if activities exist, goal is active, and has activities
    if (activityBox.isNotEmpty &&
        getGoalEndDayCount() > -1 &&
        getActivitiesCountByGoalId() > 0) {
      return Container();
    }

    // Otherwise show FAB
    return FloatingActionButton(
      onPressed: () {
        goToActivityTypeFormScreen(context);
      },
      backgroundColor: Colors.lightGreen,
      child: const Icon(Icons.add),
    );
  }

  /// FIX: Proper numeric sorting instead of string sorting
  /// Handles null/empty ranks gracefully by treating them as high values
  List<ActivityTypeModel> getSortedActivityTypes() {
    var activityTypeList = activityTypeBox.values.toList().cast<ActivityTypeModel>();
    
    // Sort by rank as INTEGER, not string
    // This fixes: "1", "10", "2" → "1", "2", "10"
    activityTypeList.sort((a, b) {
      int rankA = int.tryParse(a.rank ?? '') ?? 999999;
      int rankB = int.tryParse(b.rank ?? '') ?? 999999;
      
      return rankA.compareTo(rankB);
    });
    
    return activityTypeList;
  }

  /// Update all ranks after reordering via drag-and-drop
  /// This ensures ranks stay sequential (1, 2, 3, 4...)
  Future<void> updateActivityTypeRanks(List<ActivityTypeModel> reorderedList) async {
    for (int i = 0; i < reorderedList.length; i++) {
      final activityType = reorderedList[i];
      final newRank = (i + 1).toString();
      
      // Find the Hive key for this activity type
      final key = activityTypeBox.keys.firstWhere(
        (k) => (activityTypeBox.get(k) as ActivityTypeModel).activityTypeId == activityType.activityTypeId,
        orElse: () => null,
      );
      
      if (key != null) {
        // Create updated model with new rank
        final updatedActivityType = ActivityTypeModel(
          activityType.activityTypeId,
          activityType.activityName,
          activityType.fullScore,
          newRank,
        );
        
        // Save to Hive
        await activityTypeBox.put(key, updatedActivityType);
      }
    }
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
                // Get properly sorted list
                var activityTypeList = getSortedActivityTypes();

                // Use ReorderableListView for drag-and-drop functionality
                return ReorderableListView.builder(
                  itemCount: activityTypeList.length,
                  physics: const AlwaysScrollableScrollPhysics(),
                  onReorder: (int oldIndex, int newIndex) async {
                    setState(() {
                      // Adjust newIndex if moving item down the list
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      
                      // Reorder in the list
                      final item = activityTypeList.removeAt(oldIndex);
                      activityTypeList.insert(newIndex, item);
                    });
                    
                    // Save new order to database
                    await updateActivityTypeRanks(activityTypeList);
                  },
                  itemBuilder: (context, index) {
                    ActivityTypeModel activityTypeData = activityTypeList[index];

                    return ListTile(
                      // Unique key required for ReorderableListView
                      key: ValueKey(activityTypeData.activityTypeId),
                      // Drag handle for reordering
                      leading: Icon(
                        Icons.drag_handle,
                        color: Colors.grey[600],
                      ),
                      title: Text(activityTypeData.activityName),
                      subtitle: Text('Full Score: ${activityTypeData.fullScore}'),
                      trailing: getListTileTrailingIconButton(
                          activityTypeData.activityTypeId),
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
          if (didPop) return;
          goToSettingScreen(context);
          return;
        });
  }
}