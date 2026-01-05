import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:pingy/screens/home.dart';
import 'package:pingy/models/hive/rewards.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import 'package:pingy/widgets/FutureWidgets.dart';
import 'package:pingy/widgets/CustomAppBar.dart';
import 'package:pingy/widgets/PaddedFormField.dart';

import 'package:pingy/utils/navigators.dart';

class GoalScreen extends StatefulWidget {
  @override
  GoalScreenState createState() => GoalScreenState();
}

class GoalScreenState extends State<GoalScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _startPeriodController = TextEditingController();
  final TextEditingController _firstPrizeController = TextEditingController();
  final TextEditingController _secondPrizeController = TextEditingController();
  final TextEditingController _thirdPrizeController = TextEditingController();

  String _selectedDate = '';
  String _dateCount = '';
  String _range = '';
  String _rangeCount = '';
  String startDate = '';
  String endDate = '';

  late final Box rewardsBox;
  late final Box activityBox;

  @override
  void initState() {
    super.initState();
    // Get reference to an already opened box
    rewardsBox = Hive.box('rewards');
    activityBox = Hive.box('activity');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _startPeriodController.dispose();
    _firstPrizeController.dispose();
    _secondPrizeController.dispose();
    _thirdPrizeController.dispose();
    super.dispose();
  }

  void _onSelectionChanged(DateRangePickerSelectionChangedArgs args) {
    setState(() {
      if (args.value is PickerDateRange) {
        startDate = DateFormat('dd/MM/yyyy').format(args.value.startDate);
        endDate = DateFormat('dd/MM/yyyy')
            .format(args.value.endDate ?? args.value.startDate);

        _range = '${DateFormat('dd/MM/yyyy').format(args.value.startDate)} -'
            // ignore: lines_longer_than_80_chars
            ' ${DateFormat('dd/MM/yyyy').format(args.value.endDate ?? args.value.startDate)}';
        _startPeriodController.text = '$startDate to $endDate';
      } else if (args.value is DateTime) {
        _selectedDate = args.value.toString();
      } else if (args.value is List<DateTime>) {
        _dateCount = args.value.length.toString();
      } else {
        _rangeCount = args.value.length.toString();
      }
    });
  }

  void _handleAddGoal() {
    // Validate inputs
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.fixed,
          content: Text('Please enter a goal title'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (startDate.isEmpty || endDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.fixed,
          content: Text('Please select an activity period'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Save the goal
    var today = DateTime.now();
    var todayDate = '${today.year}${today.month}${today.day}';
    var todayTime = '${today.hour}${today.minute}${today.second}';
    var rewardId = 'goal_$todayDate$todayTime';
    String yetToWin = '';
    String emptyPicture = '';
    
    RewardsModel newRewards = RewardsModel(
      _titleController.text,
      startDate,
      endDate,
      _firstPrizeController.text,
      _secondPrizeController.text,
      _thirdPrizeController.text,
      emptyPicture,
      rewardId,
      yetToWin,
    );
    
    rewardsBox.add(newRewards);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.fixed,
        content: Text('Goal Added!'),
        duration: Duration(seconds: 1),
      ),
    );

    // Navigate after a short delay to avoid Navigator lock
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: customAppBar(
          title: 'Add Goals',
          automaticallyImplyLeading: true,
        ),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            paddedFormField(TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Goals Title',
                labelStyle: TextStyle(
                  color: Color(0xFF6200EE),
                ),
                helperText: 'Enter your Goal title',
                suffixIcon: Icon(
                  Icons.check_circle,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6200EE)),
                ),
              ),
            )),
            paddedFormField(TextFormField(
              controller: _startPeriodController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Activity Period',
                labelStyle: TextStyle(
                  color: Color(0xFF6200EE),
                ),
                helperText: 'Choose activity period',
                suffixIcon: Icon(
                  Icons.calendar_month,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6200EE)),
                ),
              ),
              onTap: () async {
                showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return Wrap(
                      children: [
                        SfDateRangePicker(
                          onSelectionChanged: _onSelectionChanged,
                          enablePastDates: false,
                          selectionMode: DateRangePickerSelectionMode.range,
                        ),
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Done',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            )),
            paddedFormField(TextFormField(
              controller: _firstPrizeController,
              decoration: const InputDecoration(
                labelText: '1st Prize',
                labelStyle: TextStyle(
                  color: Color(0xFF6200EE),
                ),
                helperText: 'Enter First Prize those who score 95% or above',
                suffixIcon: Icon(
                  Icons.check_circle,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6200EE)),
                ),
              ),
            )),
            paddedFormField(TextFormField(
              controller: _secondPrizeController,
              decoration: const InputDecoration(
                labelText: '2nd Prize',
                labelStyle: TextStyle(
                  color: Color(0xFF6200EE),
                ),
                helperText: 'Enter Second Prize those who score 85% or above',
                suffixIcon: Icon(
                  Icons.check_circle,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6200EE)),
                ),
              ),
            )),
            paddedFormField(TextFormField(
              controller: _thirdPrizeController,
              decoration: const InputDecoration(
                labelText: '3rd Prize',
                labelStyle: TextStyle(
                  color: Color(0xFF6200EE),
                ),
                helperText: 'Enter Third Prize those who score 75% or above',
                suffixIcon: Icon(
                  Icons.check_circle,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6200EE)),
                ),
              ),
            )),
            ElevatedButton(
              onPressed: _handleAddGoal,
              child: const Text(
                'Add Goal',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
      onPopInvoked: (bool didPop) {
        if (didPop) return;
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            if (activityBox.values.isEmpty) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            } else {
              goToGoalsListScreen(context);
            }
          }
        });
      },
    );
  }
}