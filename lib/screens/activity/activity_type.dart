import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:pingy/models/hive/activity_type.dart';
import 'package:pingy/utils/navigators.dart';

import 'package:pingy/widgets/FutureWidgets.dart';

class TaskTypeScreen extends StatefulWidget {
  @override
  _TaskTypeScreenState createState() => _TaskTypeScreenState();
}

class _TaskTypeScreenState extends State<TaskTypeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _fullScoreController = TextEditingController();

  late final Box activityTypeBox;

  @override
  void initState() {
    super.initState();
    // Get reference to an already opened box
    activityTypeBox = Hive.box('activity_type');
  }

  @override
  void dispose() {
    // Close Hive Connection.
    // Hive.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: Scaffold(
          appBar: AppBar(title: const Text('Pingy (Add Activity Type)')),
          body: Container(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  cursorColor: Theme.of(context).backgroundColor,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.label),
                    labelText: 'Activity Type Name',
                    labelStyle: TextStyle(
                      color: Color(0xFF6200EE),
                    ),
                    helperText: 'Enter your activity type name',
                    suffixIcon: Icon(
                      Icons.check_circle,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF6200EE)),
                    ),
                  ),
                ),
                TextFormField(
                  controller: _fullScoreController,
                  cursorColor: Theme.of(context).backgroundColor,
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
                      borderSide: BorderSide(color: Color(0xFF6200EE)),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    var today = DateTime.now();
                    var todayDate = '${today.year}${today.month}${today.day}';
                    var todayTime =
                        '${today.hour}${today.minute}${today.second}';
                    var activityTypeId = 'type_${todayDate}${todayTime}';

                    ActivityTypeModel newActivityType = ActivityTypeModel(
                        activityTypeId,
                        _nameController.text,
                        _fullScoreController.text);
                    activityTypeBox.put(activityTypeId, newActivityType);

                    await showToast('Activity Type Added!');

                    goToActivityTypeListScreen(context);
                  },
                  // padding: const EdgeInsets.only(left: 30, right: 30, top: 15, bottom: 15),
                  // color: Colors.pink,
                  child: const Text(
                    'Add Activity Type',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
        onWillPop: () async {
          goToActivityTypeListScreen(context);
          return true;
        });
  }
}
