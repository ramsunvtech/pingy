import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:pingy/models/hive/activity.dart';
import 'package:pingy/models/hive/activity_item.dart';
import 'package:pingy/models/hive/activity_type.dart';
import 'package:pingy/utils/navigators.dart';
import 'package:pingy/services/notification.dart';
import 'package:pingy/services/activity.dart';

import 'package:pingy/widgets/FutureWidgets.dart';
import 'package:pingy/widgets/CustomAppBar.dart';
import 'package:pingy/widgets/ProgressSelector.dart';

import 'package:pingy/utils/color.dart';

class UpdateTaskScreen extends StatefulWidget {
  final String? activityId;

  const UpdateTaskScreen({this.activityId = ""});

  @override
  _UpdateTaskScreenState createState() => _UpdateTaskScreenState();
}

class _UpdateTaskScreenState extends State<UpdateTaskScreen>
    with WidgetsBindingObserver {
  int defaultActivityTabIndex = 1;

  Iterable<ActivityItem> missedActivities = [];
  Iterable<ActivityItem> todoActivities = [];
  Iterable<ActivityItem> completedActivities = [];

  final TextEditingController _fullScoreController = TextEditingController();

  final _activateFormKey = GlobalKey<FormState>();

  late final Box activityBox;
  late final Box activityTypeBox;

  /// FIX: Safe method to get ActivityType by activityTypeId
  /// Searches by activityTypeId field instead of relying on Hive key
  ActivityTypeModel? getActivityTypeById(String activityTypeId) {
    if (activityTypeBox.isEmpty) return null;
    
    // Search through all values to find matching activityTypeId
    for (var key in activityTypeBox.keys) {
      final activityType = activityTypeBox.get(key) as ActivityTypeModel?;
      if (activityType?.activityTypeId == activityTypeId) {
        return activityType;
      }
    }
    
    return null;
  }

  void splitActivitiesForTabs() {
    dynamic todayActivity = activityBox.get(getActivityId());
    if (todayActivity != null && todayActivity.isInBox) {
      if (todayActivity.activityItems.isNotEmpty) {
        missedActivities = todayActivity.activityItems
            .where((element) => element.score == "0");
        todoActivities =
            todayActivity.activityItems.where((element) => element.score == "");
        completedActivities = todayActivity.activityItems
            .where((element) => element.score != "" && element.score != "0");
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Get reference to an already opened box
    activityBox = Hive.box('activity');
    activityTypeBox = Hive.box('activity_type');
    splitActivitiesForTabs();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Force rebuild when app comes back from background
      setState(() {
        splitActivitiesForTabs();
      });
    }
  }

  Widget getUpdateActivityForm(BuildContext content, dynamic todoActivity) {
    Activity todayActivity = getActivityDetails();
    // ✅ RESET / PREFILL ACTIVITY SCORE
    _fullScoreController.text = todoActivity.score ?? '';
    
    // FIX: Use safe getter instead of direct .get()
    ActivityTypeModel? todayActivityItemDetail =
        getActivityTypeById(todoActivity.activityItemId);
    
    // Handle case where activity type is not found
    if (todayActivityItemDetail == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Activity type not found. Please contact support.',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }
    
    final int fullScore = int.parse(todayActivityItemDetail.fullScore);
    final int currentScore = int.tryParse(todoActivity.score ?? '') ?? 0;
    final double? initialPercentage =
        currentScore > 0 ? currentScore / fullScore : null;

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setModalState) {
        return Form(
          key: _activateFormKey,
          child: SizedBox(
            height:
                MediaQuery.of(context).size.height * 0.85, // ⬅️ sheet height
            child: Column(
              children: [
                // ───────── SCROLLABLE CONTENT ─────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        // ─── HANDLE BAR ───
                        Container(
                          height: 3,
                          width: 70,
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'How did you do?',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          todayActivityItemDetail.activityName,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ─── SCORE PREVIEW ───
                        if (_fullScoreController.text.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(
                              'Score: ${_fullScoreController.text}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // ─── PROGRESS SELECTOR ───
                        SizedBox(
                          height: 420,
                          child: ProgressSelectorContent(
                            initialPercentage: initialPercentage,
                            showConfirmButton: false,
                            onSelected: (percentage, label) {
                              final calculatedScore =
                                  (percentage * fullScore).round();
                              setModalState(() {
                                _fullScoreController.text =
                                    calculatedScore.toString();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ───────── FIXED BOTTOM BUTTONS ─────────
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Row(
                      children: [
                        // CANCEL
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _fullScoreController.clear();
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // UPDATE
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.withOpacity(0.12),
                              foregroundColor: Colors.green,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(
                                color: Colors.green.withOpacity(0.6),
                                width: 1,
                              ),
                            ),
                            onPressed: _fullScoreController.text.isEmpty
                                ? null
                                : () async {
                                    var updatedActivity = ActivityItem(
                                      todoActivity.activityItemId,
                                      _fullScoreController.text,
                                    );

                                    var index =
                                        todayActivity.activityItems.indexWhere(
                                      (e) =>
                                          e.activityItemId ==
                                          todoActivity.activityItemId,
                                    );

                                    if (todayActivity.isInBox) {
                                      todayActivity.activityItems
                                          .setAll(index, [updatedActivity]);
                                      await todayActivity.save();
                                    }

                                    // ✅ UPDATE ONGOING NOTIFICATION
                                    await _updateOngoingNotification();

                                    _fullScoreController.clear();
                                    setState(() => defaultActivityTabIndex = 2);
                                    Navigator.pop(context, true);
                                  },
                            child: const Text(
                              'Update',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
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

  String getAppBarTitle() {
    if (widget.activityId != '') {
      Activity activityDetails = getActivityDetails();
      if (activityDetails!.activityDate != null) {
        DateFormat dateFormat = DateFormat("dd/MM/yyyy");
        String formattedDate =
            '(${dateFormat.format(activityDetails!.activityDate as DateTime)})';
        return 'Edit Activity $formattedDate';
      }

      return 'Edit Activity';
    }
    return 'Activities Today';
  }

  // TODO: fix this optional value.
  String? getActivityId() {
    if (widget.activityId != '') {
      return widget.activityId;
    }

    var today = DateTime.now();
    var activityId = 'activity_${today.year}${today.month}${today.day}';
    return activityId;
  }

  Activity getActivityDetails() {
    Activity todayActivity = activityBox.get(getActivityId());
    return todayActivity;
  }

  /// Helper method to update ongoing notification after activity is logged
  Future<void> _updateOngoingNotification() async {
    try {
      final scoreDetails = getScoreDetails();
      final activeGoal = getActiveGoalForActivities();
      
      if (activeGoal != null) {
        await NotificationService.showOngoingProgress(
          todayScore: scoreDetails['todayScore']?.toString() ?? '0',
          totalScore: scoreDetails['totalScore']?.toString() ?? '0',
          goalTitle: activeGoal.title,
        );
        print('✅ Ongoing notification updated');
      }
    } catch (e) {
      print('❌ Error updating ongoing notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    Activity todayActivity = getActivityDetails();

    String getTodoTabTitle() {
      return 'To do (${todoActivities.length.toString()})';
    }

    return PopScope(
      canPop: true,
      child: DefaultTabController(
        length: 3,
        initialIndex: defaultActivityTabIndex,
        child: Scaffold(
          appBar: customAppBar(
            bottom: TabBar(
              unselectedLabelColor: greyColor,
              labelColor: purpleColor,
              dividerColor: purpleColor,
              indicatorColor: purpleColor,
              tabs: [
                const Tab(
                  text: 'Missed',
                ),
                Tab(
                  text: getTodoTabTitle(),
                ),
                const Tab(
                  text: 'Done',
                ),
              ],
            ),
            title: getAppBarTitle(),
            leading: IconButton(
              onPressed: () {
                goToHomeScreen(context);
              },
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          body: TabBarView(
            children: [
              (missedActivities.isEmpty)
                  ? const Center(
                      child:
                          Text('No missed Activities are available. its Empty'),
                    )
                  : ListView.builder(
                      itemCount: missedActivities.length,
                      itemBuilder: (BuildContext context, int index) {
                        var missedActivity = missedActivities.elementAt(index);
                        // FIX: Use safe getter
                        ActivityTypeModel? missedActivityItemDetail =
                            getActivityTypeById(missedActivity.activityItemId);
                        
                        if (missedActivityItemDetail == null) {
                          return ListTile(
                            title: Text('Unknown Activity'),
                            subtitle: Text('Activity type not found'),
                          );
                        }

                        return taskItem(
                          'missed',
                          missedActivityItemDetail.activityName,
                          missedActivity.score ?? '0',
                          missedActivity,
                          false,
                          index,
                        );
                      },
                    ),
              (todoActivities.isEmpty)
                  ? Center(
                      child: Text((todoActivities.isEmpty &&
                              completedActivities.length ==
                                  todayActivity.activityItems.length)
                          ? 'Cool, You are done for the day!'
                          : 'No Activities are available. its Empty'),
                    )
                  : ListView.builder(
                      itemCount: todoActivities.length,
                      itemBuilder: (BuildContext context, int index) {
                        var todoActivity = todoActivities.elementAt(index);
                        // FIX: Use safe getter
                        ActivityTypeModel? todayActivityItemDetail =
                            getActivityTypeById(todoActivity.activityItemId);
                        
                        if (todayActivityItemDetail == null) {
                          return ListTile(
                            title: Text('Unknown Activity'),
                            subtitle: Text('Activity type not found'),
                          );
                        }

                        return Dismissible(
                            key: UniqueKey(),
                            child: taskItem(
                                'todo',
                                todayActivityItemDetail.activityName,
                                'Swipe left to skip / right to update score',
                                todoActivity,
                                false,
                                index),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.startToEnd) {
                                // Update Box with 0 as score.
                                // return true;
                                return await showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(25),
                                      topRight: Radius.circular(25),
                                    ),
                                  ),
                                  builder: (context) =>
                                      DraggableScrollableSheet(
                                          initialChildSize: 0.90,
                                          maxChildSize: 0.97,
                                          minChildSize: 0.85,
                                          expand: false,
                                          builder: (context, scrollController) {
                                            return SingleChildScrollView(
                                              controller: scrollController,
                                              child: Padding(
                                                padding: MediaQuery.of(context)
                                                    .viewInsets,
                                                child: getUpdateActivityForm(
                                                    context, todoActivity),
                                              ),
                                            );
                                          }),
                                );
                              } else if (direction ==
                                  DismissDirection.endToStart) {
                                var updatedMissedActivity = ActivityItem(
                                    todoActivity.activityItemId, '0');
                                var activityItemIndex = todayActivity
                                    .activityItems
                                    .indexWhere((element) =>
                                        element.activityItemId ==
                                        todoActivity.activityItemId);

                                if (todayActivity.isInBox) {
                                  todayActivity.activityItems.setAll(
                                      activityItemIndex,
                                      [updatedMissedActivity]);
                                  await todayActivity.save();
                                }

                                // ✅ UPDATE ONGOING NOTIFICATION
                                await _updateOngoingNotification();

                                // Update Box with score.
                                splitActivitiesForTabs();
                                setState(() {});
                                return true;
                              }
                            },
                            onDismissed: (direction) {
                              var textMessage = 'not set';

                              switch (direction) {
                                case DismissDirection.startToEnd:
                                  textMessage = 'right';
                                  break;
                                case DismissDirection.endToStart:
                                  textMessage = 'left';
                                  break;
                                default:
                                  textMessage = 'default';
                                  break;
                              }
                              if (textMessage != '') {
                                String toastMessage = '';
                                if (textMessage == 'right') {
                                  toastMessage =
                                      'Activity completed successfully with specified Score.';
                                } else {
                                  toastMessage =
                                      'Activity marked as missed successfully.';
                                }
                                showToastMessage(context, toastMessage);
                              }
                            });
                      },
                    ),
              (completedActivities.isEmpty)
                  ? const Center(
                      child: Text(
                          'No Completed Activities are available. its Empty'),
                    )
                  : ListView.builder(
                      itemCount: completedActivities.length,
                      itemBuilder: (BuildContext context, int index) {
                        var completedActivity =
                            completedActivities.elementAt(index);
                        // FIX: Use safe getter
                        ActivityTypeModel? completedActivityItemDetail =
                            getActivityTypeById(completedActivity.activityItemId);
                        
                        if (completedActivityItemDetail == null) {
                          return ListTile(
                            title: Text('Unknown Activity'),
                            subtitle: Text('Activity type not found'),
                          );
                        }

                        return taskItem(
                          'completed',
                          completedActivityItemDetail.activityName,
                          completedActivity.score,
                          completedActivity,
                          false,
                          index,
                        );
                      },
                    )
            ],
          ),
        ),
      ),
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        goToHomeScreen(context);
        return;
      },
    );
  }

  Widget taskItem(String taskType, String taskName, String? mark,
      ActivityItem selectActivity, bool isSelected, int index) {
    var enabled = true;
    IconData taskIcon = Icons.content_paste;
    dynamic taskScore = '';

    if (taskType == 'missed') {
      taskIcon = Icons.content_paste_off;
      taskScore = 'You missed this task';
    } else if (taskType == 'todo') {
      taskScore = mark;
    } else if (taskType == 'completed') {
      taskIcon = Icons.assignment_turned_in_outlined;
      String activityItemId = selectActivity.activityItemId;
      if (mark != '' && activityItemId.isNotEmpty) {
        // FIX: Use safe getter
        ActivityTypeModel? activityTypeDetails =
            getActivityTypeById(activityItemId);
        if (activityTypeDetails != null) {
          taskScore = 'You scored $mark out of ${activityTypeDetails.fullScore}';
        } else {
          taskScore = 'Score: $mark';
        }
      }
    }

    Widget subtitle = Text(taskScore);

    return ListTile(
      enabled: enabled,
      leading: CircleAvatar(
        backgroundColor: lightGreenColor,
        child: Icon(
          taskIcon,
          color: iconColor,
        ),
      ),
      title: Text(
        taskName,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle,
      onTap: () async {
        return await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(30),
            ),
          ),
          builder: (context) => DraggableScrollableSheet(
              initialChildSize: 0.85,
              maxChildSize: 0.95,
              minChildSize: 0.80,
              expand: false,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: MediaQuery.of(context).viewInsets,
                    child: getUpdateActivityForm(context, selectActivity),
                  ),
                );
              }),
        );
      },
    );
  }
}