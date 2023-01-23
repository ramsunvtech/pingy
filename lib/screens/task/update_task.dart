import 'package:flutter/material.dart';
import 'package:pingy/models/TaskType.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Pingy (Update Task)')),
      body: SafeArea(
          child: Column(
        children: [
          Center(
            child: Text(
              'Date: ${todayDate.year}${todayDate.month}${todayDate.day}',
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
            cursorColor: Theme.of(context).cursorColor,
            initialValue: '0',
            maxLength: 3,
            decoration: InputDecoration(
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
            icon: Icon(Icons.add, size: 18),
            label: Text("Update Task"),
          )
        ],
      )),
    );
  }

  Widget taskItem(String taskName, int mark, bool isSelected, int index) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green[700],
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
      trailing: isSelected
          ? const Icon(
              Icons.check_circle,
              color: Colors.green,
            )
          : const Icon(
              Icons.check_circle_outline,
              color: Colors.grey,
            ),
      onTap: () {
        setState(() {
          taskTypes[index].isSelected = !taskTypes[index].isSelected;
          if (taskTypes[index].isSelected == true) {
            selectedTaskType = TaskTypeModel(taskName, 160, true);
          }
          taskTypes[index].isSelected = false;
        });
      },
    );
  }
}
