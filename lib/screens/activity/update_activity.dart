import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:pingy/models/activity.dart';
import 'package:pingy/models/task_type.dart';
import 'package:pingy/screens/home.dart';

class UpdateTaskScreen extends StatefulWidget {
  @override
  _UpdateTaskScreenState createState() => _UpdateTaskScreenState();
}

class _UpdateTaskScreenState extends State<UpdateTaskScreen> {
  final TextEditingController _scoreController = TextEditingController();

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
    var activityKey = '${todayDate.year}${todayDate.month}${todayDate.day}';

    return Scaffold(
      appBar: AppBar(title: const Text('Pingy (Update Activity)')),
      body: SafeArea(
        child: Column(
          children: [
            Center(
              child: Text(
                'Date: #$activityKey',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                    fontStyle: FontStyle.italic),
              ),
            ),
            Expanded(
                child: ListView.builder(
              itemCount: activityTypeBox.length,
              itemBuilder: (BuildContext context, int index) {
                var activityType = activityTypeBox.getAt(index)!;
                bool isSelected = true;
                return taskItem(
                  activityType.activityName,
                  activityType.fullScore,
                  isSelected,
                  index,
                );
              },
            )),
            Center(
              child: Text(
                'Selected Task: ${selectedTaskType.taskName}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                    fontStyle: FontStyle.italic),
              ),
            ),
            TextFormField(
              controller: _scoreController,
              cursorColor: Theme.of(context).backgroundColor,
              keyboardType: TextInputType.number,
              maxLength: 3,
              decoration: const InputDecoration(
                icon: Icon(Icons.favorite),
                labelText: 'Task Score',
                labelStyle: TextStyle(
                  color: Color(0xFF6200EE),
                ),
                helperText: 'Enter your score',
                suffixIcon: Icon(
                  Icons.check_circle,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6200EE)),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                var todayDate = DateTime.now();
                var activityId =
                    '${todayDate.year}${todayDate.month}${todayDate.day}';
                Activity newActivity = Activity(activityId,
                    selectedTaskType.taskName, _scoreController.text);
                activityBox.add(newActivity);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (builder) => HomeScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Update Task"),
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
      onTap: () {
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
