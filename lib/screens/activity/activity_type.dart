import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:pingy/models/hive/activity_type.dart';
import 'package:pingy/utils/navigators.dart';
import 'package:pingy/widgets/CustomAppBar.dart';
import 'package:pingy/widgets/FutureWidgets.dart';
import 'package:pingy/widgets/PaddedFormField.dart';

class TaskTypeScreen extends StatefulWidget {
  final String? activityTypeId;

  const TaskTypeScreen({this.activityTypeId = ""});

  @override
  _TaskTypeScreenState createState() => _TaskTypeScreenState();
}

class _TaskTypeScreenState extends State<TaskTypeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _fullScoreController = TextEditingController();
  final TextEditingController _rankController = TextEditingController();

  String formMode = 'add';

  late final Box activityTypeBox;

  @override
  void initState() {
    super.initState();
    // Get reference to an already opened box
    activityTypeBox = Hive.box('activity_type');

    if (widget.activityTypeId != '') {
      formMode = 'edit';
    }
  }

  // TODO: fix this optional value.
  String? getActivityTypeId() {
    if (widget.activityTypeId != '') {
      formMode = 'edit';
      return widget.activityTypeId;
    }
    return '';
  }

  ActivityTypeModel getActivityTypeDetails() {
    String? activityTypeId = getActivityTypeId();
    ActivityTypeModel activityType = activityTypeBox.get(activityTypeId);
    return activityType;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (formMode == 'edit') {
      ActivityTypeModel editingActivityType = getActivityTypeDetails();
      _nameController.text = editingActivityType.activityName;
      _fullScoreController.text = editingActivityType.fullScore;
      _rankController.text = '0';
      if (editingActivityType.rank != null) {
        _rankController.text = editingActivityType.rank!;
      }
    }

    return PopScope(
        child: Scaffold(
          appBar: customAppBar(
              title: (formMode == 'edit')
                  ? 'Edit Activity Type'
                  : 'Add Activity Type'),
          body: Container(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                paddedFormField(TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
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
                )),
                paddedFormField(TextFormField(
                  controller: _fullScoreController,
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                  decoration: const InputDecoration(
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
                )),
                paddedFormField(TextFormField(
                  controller: _rankController,
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                  decoration: const InputDecoration(
                    labelText: 'Activity Rank',
                    labelStyle: TextStyle(
                      color: Color(0xFF6200EE),
                    ),
                    helperText: 'Enter the activity rank',
                    suffixIcon: Icon(
                      Icons.check_circle,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF6200EE)),
                    ),
                  ),
                )),
                ElevatedButton(
                  onPressed: () {
                    var today = DateTime.now();
                    var todayDate = '${today.year}${today.month}${today.day}';
                    var todayTime =
                        '${today.hour}${today.minute}${today.second}';
                    var activityTypeId = 'type_$todayDate$todayTime';
                    String toastMessage = 'Activity Type added!';

                    if (formMode == 'edit') {
                      ActivityTypeModel editingActivityType =
                          getActivityTypeDetails();
                      activityTypeId = editingActivityType.activityTypeId;
                      toastMessage = 'Activity Type edited!';
                    }

                    ActivityTypeModel updatingActivityType = ActivityTypeModel(
                        activityTypeId,
                        _nameController.text,
                        _fullScoreController.text,
                        _rankController.text);
                    activityTypeBox.put(activityTypeId, updatingActivityType);

                    showToastMessage(context, 'Activity Type Added!');

                    goToActivityTypeListScreen(context);
                  },
                  // padding: const EdgeInsets.only(left: 30, right: 30, top: 15, bottom: 15),
                  // color: Colors.pink,
                  child: const Text(
                    'Add Activity Type',
                    style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
        onPopInvoked: (bool didPop) {
          goToActivityTypeListScreen(context);
          return;
        });
  }
}
