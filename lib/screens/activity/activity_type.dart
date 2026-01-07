import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:pingy/models/hive/activity_type.dart';

import 'package:pingy/widgets/CustomAppBar.dart';
import 'package:pingy/widgets/FutureWidgets.dart';
import 'package:pingy/widgets/PaddedFormField.dart';
import 'package:pingy/widgets/DifficultyScoreSelector.dart';

import 'package:pingy/utils/navigators.dart';

class TaskTypeScreen extends StatefulWidget {
  final String? activityTypeId;

  const TaskTypeScreen({Key? key, this.activityTypeId = ""}) : super(key: key);

  @override
  _TaskTypeScreenState createState() => _TaskTypeScreenState();
}

class _TaskTypeScreenState extends State<TaskTypeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _fullScoreController = TextEditingController();
  final TextEditingController _rankController = TextEditingController();

  late final Box activityTypeBox;
  String formMode = 'add';

  @override
  void initState() {
    super.initState();
    activityTypeBox = Hive.box('activity_type');

    if (widget.activityTypeId != null && widget.activityTypeId!.isNotEmpty) {
      formMode = 'edit';
      final model = activityTypeBox.get(widget.activityTypeId);
      if (model != null) {
        _nameController.text = model.activityName;
        _fullScoreController.text = model.fullScore;
        _rankController.text = model.rank ?? '0';
      }
    } else {
      _rankController.text = _generateRank();
    }
  }

  void _saveActivityType() {
    final id = widget.activityTypeId!.isNotEmpty
        ? widget.activityTypeId!
        : 'type_${DateTime.now().millisecondsSinceEpoch}';

    final model = ActivityTypeModel(
      id,
      _nameController.text,
      _fullScoreController.text,
      _rankController.text,
    );

    activityTypeBox.put(id, model);
    showToastMessage(context, 'Activity Type Saved');
    goToActivityTypeListScreen(context);
  }

  String _generateRank() {
    // Rank = order in box + 1
    return (activityTypeBox.length + 1).toString();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          goToActivityTypeListScreen(context);
        }
      },
      child: Scaffold(
        appBar: customAppBar(
          title:
              formMode == 'edit' ? 'Edit Activity Type' : 'Add Activity Type',
        ),

        // ✅ SCROLLABLE BODY
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              paddedFormField(
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Activity Type Name',
                    labelStyle: TextStyle(color: Color(0xFF6200EE)),
                    helperText: 'Enter your activity type name',
                    suffixIcon: Icon(Icons.check_circle),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF6200EE)),
                    ),
                  ),
                ),
              ),

              // ✅ Difficulty section
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Difficulty',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6200EE),
                  ),
                ),
              ),

              DifficultyScoreSelector(
                selectedValue: int.tryParse(_fullScoreController.text),
                onSelected: (value, term) {
                  setState(() {
                    _fullScoreController.text = value.toString();
                  });
                },
              ),

              if (_fullScoreController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: Text(
                      'Score set to ${_fullScoreController.text}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),

              paddedFormField(
                TextFormField(
                  controller: _rankController,
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                  decoration: const InputDecoration(
                    labelText: 'Activity Rank',
                    labelStyle: TextStyle(color: Color(0xFF6200EE)),
                    helperText: 'Enter the activity rank',
                    suffixIcon: Icon(Icons.check_circle),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF6200EE)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ✅ FIXED BOTTOM BUTTONS (NO OVERFLOW)
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveActivityType,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
