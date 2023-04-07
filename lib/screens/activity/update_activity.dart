import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:pingy/models/hive/activity.dart';
import 'package:pingy/models/hive/activity_item.dart';
import 'package:pingy/models/hive/activity_type.dart';
import 'package:pingy/utils/navigators.dart';

import 'package:pingy/widgets/FutureWidgets.dart';
import 'package:pingy/widgets/CustomAppBar.dart';

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

    return Form(
      key: _activateFormKey,
      child: Wrap(
        children: [
          Container(
            height: 3,
            width: 70,
            margin: const EdgeInsets.symmetric(
                vertical: 12, horizontal: 160),
            decoration: BoxDecoration(
                color: Colors.grey, borderRadius: BorderRadius.circular(8)),
          ),
          const Center(child: Text('Update')),
          Center(
            child: TextFormField(
              controller: _fullScoreController,
              cursorColor: Theme.of(context).backgroundColor,
              keyboardType: TextInputType.number,
              maxLength: 3,
              validator: (value) {
                bool hasNoValue = value == '' || value == null || value.isEmpty;
                var parsedIntegerValue = int.tryParse(value!);
                var parsedFullScoreValue =
                    int.tryParse(todayActivityItemDetail.fullScore);
                bool isValidScore = (parsedIntegerValue != null &&
                    parsedFullScoreValue != null &&
                    parsedIntegerValue > 0 &&
                    parsedIntegerValue <= parsedFullScoreValue);

                if (hasNoValue || parsedIntegerValue == 0 || !isValidScore) {
                  return 'Score should be a number between 1 and ${todayActivityItemDetail.fullScore}';
                }
                return null;
              },
              decoration: InputDecoration(
                icon: Icon(Icons.numbers),
                labelText: 'Activity Score',
                labelStyle: TextStyle(
                  color: Color(0xFF6200EE),
                ),
                helperText:
                    'Enter the activity score out of ${todayActivityItemDetail.fullScore}',
                suffixIcon: Icon(
                  Icons.check_circle,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6200EE)),
                ),
              ),
            ),
          ),
          Center(
            child: FractionallySizedBox(
              widthFactor: 0.9,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                // padding: const EdgeInsets.only(left: 30, right: 30, top: 15, bottom: 15),
                // color: Colors.pink,
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6),
                ),
              ),
            ),
          ),
          Center(
            child: FractionallySizedBox(
              widthFactor: 0.9,
              child: ElevatedButton(
                onPressed: () async {
                  if (_activateFormKey.currentState!.validate()) {
                    var updatedMissedActivity = ActivityItem(
                        todoActivity.activityItemId, _fullScoreController.text);
                    var activityItemIndex = todayActivity.activityItems
                        .indexWhere((element) =>
                    element.activityItemId ==
                        todoActivity.activityItemId);
                    if (todayActivity.isInBox) {
                      todayActivity.activityItems
                          .setAll(activityItemIndex, [updatedMissedActivity]);
                      await todayActivity.save();
                    }
                    _fullScoreController.text = '';
                    setState(() => {defaultActivityTabIndex = 2});
                    Navigator.of(context).pop(true);
                  }
                },
                // padding: const EdgeInsets.only(left: 30, right: 30, top: 15, bottom: 15),
                // color: Colors.pink,
                child: const Text(
                  'Update',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6),
                ),
              ),
            ),
          ),
        ],
      ),
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

    return WillPopScope(
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
                                          initialChildSize: 0.550,
                                          maxChildSize: 0.9,
                                          minChildSize: 0.32,
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
      onWillPop: () async {
        goToHomeScreen(context);
        return true;
      },
    );
  }

  Widget taskItem(String taskType, String taskName, String? mark, ActivityItem selectActivity,
      bool isSelected, int index) {
    var enabled = true;
    IconData taskIcon = Icons.content_paste;

    if (taskType == 'missed') {
      taskIcon = Icons.content_paste_off;
    } else if (taskType == 'completed') {
      taskIcon = Icons.assignment_turned_in_outlined;
    }

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
      subtitle: Text(mark ?? '0'),
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
              initialChildSize: 0.7,
              maxChildSize: 0.9,
              minChildSize: 0.32,
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
