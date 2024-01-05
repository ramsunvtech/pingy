import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:pingy/models/hive/rewards.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import 'package:pingy/widgets/FutureWidgets.dart';
import 'package:pingy/widgets/CustomAppBar.dart';
import 'package:pingy/widgets/PaddedFormField.dart';

import 'package:pingy/utils/navigators.dart';
import 'package:pingy/utils/color.dart';

class GoalScreen extends StatefulWidget {
  @override
  _GoalScreenState createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
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
              cursorColor: Theme.of(context).colorScheme.background,
              decoration: const InputDecoration(
                labelText: 'Goals Title',
                labelStyle: TextStyle(
                  color: Color(0xFF000000),
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
              cursorColor: Theme.of(context).colorScheme.background,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Activity Period',
                labelStyle: TextStyle(
                  color: Color(0xFF000000),
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
                          // padding: const EdgeInsets.only(left: 30, right: 30, top: 15, bottom: 15),
                          // color: Colors.pink,
                          child: const Text(
                            'Done',
                            style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.6),
                          ),
                        )),
                      ],
                    );
                  },
                );
              },
            )),
            paddedFormField(TextFormField(
              controller: _firstPrizeController,
              cursorColor: Theme.of(context).colorScheme.background,
              decoration: const InputDecoration(
                labelText: '1st Prize',
                labelStyle: TextStyle(
                  color: Color(0xFF000000),
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
              cursorColor: Theme.of(context).colorScheme.background,
              decoration: const InputDecoration(
                labelText: '2nd Prize',
                labelStyle: TextStyle(
                  color: Color(0xFF000000),
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
              cursorColor: Theme.of(context).colorScheme.background,
              decoration: const InputDecoration(
                labelText: '3rd Prize',
                labelStyle: TextStyle(
                  color: Color(0xFF000000),
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
              onPressed: () {
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
                    yetToWin);
                rewardsBox.add(newRewards);
                String toastMessage = 'Goal Added!';
                showToastMessage(context, toastMessage);
                goToHomeScreen(context);
              },
              child: const Text(
                'Add Goal',
                style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6),
              ),
            ),
          ],
        ),
      ),
      onPopInvoked: (bool didPop) {
        if (activityBox.values.isEmpty) {
          goToHomeScreen(context);
          return;
        }

        goToGoalsListScreen(context);
        return;
      },
    );
  }
}
