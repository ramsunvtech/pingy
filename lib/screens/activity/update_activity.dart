import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:pingy/models/hive/activity.dart';
import 'package:pingy/models/hive/activity_item.dart';
import 'package:pingy/models/hive/activity_type.dart';
import 'package:pingy/utils/navigators.dart';

import 'package:pingy/widgets/FutureWidgets.dart';
import 'package:pingy/widgets/CustomAppBar.dart';
import 'package:pingy/widgets/PaddedFormField.dart';
import 'package:pingy/widgets/ProgressSelector.dart';

import 'package:pingy/utils/color.dart';

class UpdateTaskScreen extends StatefulWidget {
  final String? activityId;

  const UpdateTaskScreen({this.activityId = ""});

  @override
  _UpdateTaskScreenState createState() => _UpdateTaskScreenState();
}

class _UpdateTaskScreenState extends State<UpdateTaskScreen> {
  int defaultActivityTabIndex = 1;

  Iterable<ActivityItem> missedActivities = [];
  Iterable<ActivityItem> todoActivities = [];
  Iterable<ActivityItem> completedActivities = [];

  final TextEditingController _fullScoreController = TextEditingController();

  final _activateFormKey = GlobalKey<FormState>();

  late final Box activityBox;
  late final Box activityTypeBox;

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
    // Get reference to an already opened box
    activityBox = Hive.box('activity');
    activityTypeBox = Hive.box('activity_type');
    splitActivitiesForTabs();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget getUpdateActivityForm(BuildContext content, dynamic todoActivity) {
    Activity todayActivity = getActivityDetails();
    ActivityTypeModel todayActivityItemDetail =
        activityTypeBox.get(todoActivity.activityItemId);

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setModalState) {
        return Form(
          key: _activateFormKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ─── HANDLE BAR ─────────────────────────────
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

                // ─── TITLE AND ACTIVITY NAME ─────────────────
                const Text(
                  'How did you do?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  todayActivityItemDetail.activityName,
                  style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500),
                ),

                const SizedBox(height: 16),

                // ─── SELECTED PROGRESS DISPLAY ───────────────
                if (_fullScoreController.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Score: ${_fullScoreController.text} / ${todayActivityItemDetail.fullScore}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // ─── PROGRESS SELECTOR (NO CONFIRM BUTTON) ───
                SizedBox(
                  height: 450,
                  child: ProgressSelectorContent(
                    initialPercentage: null,
                    showConfirmButton: false,
                    onSelected: (percentage, label) {
                      final fullScore =
                          int.parse(todayActivityItemDetail.fullScore);
                      final calculatedScore = (percentage * fullScore).round();

                      setModalState(() {
                        _fullScoreController.text = calculatedScore.toString();
                      });
                    },
                  ),
                ),

                const SizedBox(height: 05),

                // ─── UPDATE BUTTON ───────────────────────────
                FractionallySizedBox(
                  widthFactor: 0.9,
                  child: ElevatedButton(
                    onPressed: _fullScoreController.text.isEmpty
                        ? null
                        : () async {
                            var updatedActivity = ActivityItem(
                              todoActivity.activityItemId,
                              _fullScoreController.text,
                            );

                            var index = todayActivity.activityItems.indexWhere(
                              (e) =>
                                  e.activityItemId ==
                                  todoActivity.activityItemId,
                            );

                            if (todayActivity.isInBox) {
                              todayActivity.activityItems
                                  .setAll(index, [updatedActivity]);
                              await todayActivity.save();
                            }

                            _fullScoreController.clear();
                            setState(() => defaultActivityTabIndex = 2);
                            Navigator.pop(context, true);
                          },
                    child: const Text(
                      'Update',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
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
                        ActivityTypeModel missedActivityItemDetail =
                            activityTypeBox.get(missedActivity.activityItemId);

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
                        ActivityTypeModel todayActivityItemDetail =
                            activityTypeBox.get(todoActivity.activityItemId);

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
                                          initialChildSize: 0.85,
                                          maxChildSize: 0.95,
                                          minChildSize: 0.80,
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
                        ActivityTypeModel completedActivityItemDetail =
                            activityTypeBox
                                .get(completedActivity.activityItemId);

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
        // If the system already handled the pop, do nothing
        if (didPop) return;

        // If for some reason didPop is false (e.g. nested navigators),
        // then trigger your custom logic:
        goToHomeScreenV2(context);
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
        ActivityTypeModel activityTypeDetails =
            activityTypeBox.get(activityItemId);
        taskScore = 'You scored $mark out of ${activityTypeDetails.fullScore}';
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
