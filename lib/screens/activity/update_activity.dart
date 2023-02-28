import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:pingy/models/hive/activity.dart';
import 'package:pingy/models/hive/activity_item.dart';
import 'package:pingy/models/hive/activity_type.dart';
import 'package:pingy/models/task_type.dart';

class UpdateTaskScreen extends StatefulWidget {
  @override
  _UpdateTaskScreenState createState() => _UpdateTaskScreenState();
}

class _UpdateTaskScreenState extends State<UpdateTaskScreen> {
  int defaultActivityTabIndex = 1;

  final TextEditingController _scoreController = TextEditingController();
  final TextEditingController _fullScoreController = TextEditingController();

  final _activateFormKey = GlobalKey<FormState>();

  late final Box activityBox;
  late final Box activityTypeBox;

  @override
  void initState() {
    super.initState();
    // Get reference to an already opened box
    activityBox = Hive.box('activity');
    activityTypeBox = Hive.box('activity_type');
  }

  @override
  void dispose() {
    // Close Hive Connection.
    // Hive.close();

    super.dispose();
  }

  List<TaskTypeModel> taskTypes = [
    TaskTypeModel('Breakfast', 250, false),
    TaskTypeModel('Lunch', 150, false),
    TaskTypeModel('Dinner', 200, false),
  ];

  TaskTypeModel selectedTaskType = TaskTypeModel('default', 100, false);

  Widget getUpdateActivityForm(BuildContext content, dynamic todoActivity) {
    Activity todayActivity = getTodatyActivity();
    ActivityTypeModel todayActivityItemDetail =
        activityTypeBox.get(todoActivity.activityItemId);

    return Form(
      key: _activateFormKey,
      child: Wrap(
        children: [
          Center(child: Text('Update')),
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
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              // padding: const EdgeInsets.only(left: 30, right: 30, top: 15, bottom: 15),
              // color: Colors.pink,
              child: Text(
                'Cancel',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6),
              ),
            ),
          ),
          Center(
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
                'Completed',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Activity getTodatyActivity() {
    var today = DateTime.now();
    var activityId = 'activity_${today.year}${today.month}${today.day}';
    Activity todayActivity = activityBox.get(activityId);
    return todayActivity;
  }

  @override
  Widget build(BuildContext context) {
    Activity todayActivity = getTodatyActivity();
    Iterable<ActivityItem> missedActivities = [];
    Iterable<ActivityItem> todoActivities = [];
    Iterable<ActivityItem> completedActivities = [];

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

    String getTodoTabTitle() {
      return 'To do (${todoActivities.length.toString()})';
    }

    return DefaultTabController(
      length: 3,
      initialIndex: defaultActivityTabIndex,
      child: Scaffold(
        appBar: AppBar(
            bottom: TabBar(
              tabs: [
                Tab(
                  text: 'Missed',
                ),
                Tab(
                  text: getTodoTabTitle(),
                ),
                Tab(
                  text: 'Done',
                ),
              ],
            ),
            title: const Text('Activity Today')),
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
                          key: Key('item_${index + 1}'),
                          child: taskItem(
                              todayActivityItemDetail.activityName,
                              'Swipe right to add score / left to mark as missed',
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
                                builder: (BuildContext context) {
                                  return Padding(
                                    padding: MediaQuery.of(context).viewInsets,
                                    child: getUpdateActivityForm(
                                        context, todoActivity),
                                  );
                                },
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
                                    activityItemIndex, [updatedMissedActivity]);
                                await todayActivity.save();
                              }

                              setState(() => {defaultActivityTabIndex = 0});

                              // Update Box with score.
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(toastMessage)));
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
                          activityTypeBox.get(completedActivity.activityItemId);

                      return taskItem(
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
    );
  }

  Widget taskItem(String taskName, String? mark, ActivityItem selectActivity,
      bool isSelected, int index) {
    var enabled = true;

    return ListTile(
      enabled: enabled,
      leading: CircleAvatar(
        backgroundColor: isSelected ? Colors.green[700] : Colors.grey,
        child: const Icon(
          Icons.person_outline_outlined,
          color: Colors.white,
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
          builder: (BuildContext context) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: getUpdateActivityForm(context, selectActivity),
            );
          },
        );
      },
    );
  }
}
