import 'package:flutter/material.dart';
import 'package:pingy/models/task_type.dart';

class UpdateTaskScreen extends StatefulWidget {
  @override
  _UpdateTaskScreenState createState() => _UpdateTaskScreenState();
}

class _UpdateTaskScreenState extends State<UpdateTaskScreen> {

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
      appBar: AppBar(title: const Text('Pingy (Update Task)')),
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
          Center(
            child: Text(
              'Selected Task: ${selectedTaskType.taskName}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                  fontStyle: FontStyle.italic),
            ),
          ),
          Expanded(
              child: ListView.builder(
                itemCount: taskTypes.length,
                itemBuilder: (BuildContext context, int index) {
                  return taskItem(
                    taskTypes[index].taskName,
                    taskTypes[index].mark,
                    taskTypes[index].isSelected,
                    index,
                  );
                },
          )),
          TextFormField(
            cursorColor: Theme.of(context).backgroundColor,
            initialValue: '0',
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
              // Respond to button press
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text("Update Task"),
          )
        ],
      )),
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
  Widget taskItem(String taskName, int mark, bool isSelected, int index) {
    var enabled = true;
    // var trailingIcon = Icons.check_circle_outline;
    // var trailingIconColor = Colors.grey;
    // Colors trailingIconColor2 = const Colors.grey;

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
      subtitle: const Text('Task Type description'),
      trailing: getTrailingIcon(isSelected),
      onTap: () {
        setState(() {
          taskTypes[0].isSelected = false;
          taskTypes[1].isSelected = false;
          taskTypes[2].isSelected = false;
          taskTypes[index].isSelected = !taskTypes[index].isSelected;
          if (taskTypes[index].isSelected == true) {
            selectedTaskType = TaskTypeModel(taskName, 160, true);
          }
        });
      },
    );
  }
}
