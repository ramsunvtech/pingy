import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:pingy/models/hive/activity.dart';
import 'package:pingy/models/task_type.dart';
import 'package:pingy/screens/home.dart';

class UpdateTaskScreen extends StatefulWidget {
  @override
  _UpdateTaskScreenState createState() => _UpdateTaskScreenState();
}

class _UpdateTaskScreenState extends State<UpdateTaskScreen> {
  final TextEditingController _scoreController = TextEditingController();
  final TextEditingController _fullScoreController = TextEditingController();

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

  final List<Widget> homePanes = [
    const Center(
      child: Image(
        image: AssetImage('assets/cute.webp'),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    var todayDate = DateTime.now();

    return DefaultTabController(
      length: 3,
      initialIndex: 1,
      child: Scaffold(
        appBar: AppBar(
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Missed'),
                Tab(text: 'To do'),
                Tab(text: 'Done'),
              ],
            ),
            title: const Text('Update Activity')),
        body: TabBarView(
          children: [
            ListView.builder(
              itemCount: 3,
              itemBuilder: (BuildContext context, int index) {
                return taskItem(
                  'Missed Activity ${index + 1}',
                  '160',
                  false,
                  index,
                );
              },
            ),
            ListView.builder(
              itemCount: 3,
              itemBuilder: (BuildContext context, int index) {
                return Dismissible(
                    key: Key('item_${index + 1}'),
                    child: taskItem(
                      'Activity ${index + 1} To do',
                      '160',
                      false,
                      index,
                    ),
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
                              child: Wrap(
                                children: [
                                  Center(child: Text('Update')),
                                  Center(
                                    child: TextFormField(
                                      controller: _fullScoreController,
                                      cursorColor:
                                      Theme.of(context).backgroundColor,
                                      keyboardType: TextInputType.number,
                                      maxLength: 3,
                                      decoration: const InputDecoration(
                                        icon: Icon(Icons.numbers),
                                        labelText: 'Activity Score',
                                        labelStyle: TextStyle(
                                          color: Color(0xFF6200EE),
                                        ),
                                        helperText: 'Enter the activity score',
                                        suffixIcon: Icon(
                                          Icons.check_circle,
                                        ),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Color(0xFF6200EE)),
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
                                      child: const Text(
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
                                      onPressed: () {
                                        Navigator.of(context).pop(true);
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
                          },
                        );
                      } else if (direction == DismissDirection.endToStart) {
                        // Update Box with score.
                        return true;
                      }
                    },
                    onDismissed: (direction) {
                      var textMessage = 'not set';

                      switch (direction) {
                        case DismissDirection.startToEnd:
                          textMessage = "left";
                          break;
                        case DismissDirection.endToStart:
                          textMessage = "right";
                          break;
                      }
                      if (textMessage != '') {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('swiped $textMessage')));
                      }
                    });
              },
            ),
            ListView.builder(
              itemCount: 3,
              itemBuilder: (BuildContext context, int index) {
                return taskItem(
                  'Completed Activity ${index + 1}',
                  '160',
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

  Widget getTrailingIcon(bool isSelected) {
    if (isSelected) {
      return const Icon(
        Icons.check_circle,
        color: Colors.green,
      );
    }
    return const Icon(
      Icons.check_circle_outline,
      color: Colors.grey,
    );
  }

  Widget taskItem(String taskName, String mark, bool isSelected, int index) {
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
      subtitle: Text(mark),
      trailing: getTrailingIcon(isSelected),
      onTap: () async {
        setState(() {
          taskTypes[0].isSelected = false;
          taskTypes[1].isSelected = false;
          taskTypes[2].isSelected = false;
          taskTypes[index].isSelected = !taskTypes[index].isSelected;
          if (taskTypes[index].isSelected == true) {
            _scoreController.text = taskTypes[index].mark.toString();
            selectedTaskType = TaskTypeModel(taskName, 160, true);
          }
        });
      },
    );
  }
}
