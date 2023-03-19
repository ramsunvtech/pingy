import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:pingy/models/hive/rewards.dart';
import 'package:pingy/widgets/FutureWidgets.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import 'package:pingy/utils/navigators.dart';

class RewardsScreen extends StatefulWidget {
  @override
  _RewardsScreenState createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
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
    // Close Hive Connection.
    // Hive.close();

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
    return WillPopScope(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text('Add Goals'),
          automaticallyImplyLeading: true,
        ),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: _titleController,
              cursorColor: Theme.of(context).colorScheme.background,
              decoration: const InputDecoration(
                icon: Icon(Icons.label),
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
            ),
            TextFormField(
              controller: _startPeriodController,
              cursorColor: Theme.of(context).colorScheme.background,
              readOnly: true,
              decoration: const InputDecoration(
                icon: Icon(Icons.calendar_today),
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
                          // padding: const EdgeInsets.only(left: 30, right: 30, top: 15, bottom: 15),
                          // color: Colors.pink,
                          child: const Text(
                            'Done',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.6),
                          ),
                        )),
                      ],
                    );
                  },
                );
              },
            ),
            TextFormField(
              controller: _firstPrizeController,
              cursorColor: Theme.of(context).colorScheme.background,
              decoration: const InputDecoration(
                icon: Icon(Icons.numbers),
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
            ),
            TextFormField(
              controller: _secondPrizeController,
              cursorColor: Theme.of(context).colorScheme.background,
              decoration: const InputDecoration(
                icon: Icon(Icons.numbers),
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
            ),
            TextFormField(
              controller: _thirdPrizeController,
              cursorColor: Theme.of(context).colorScheme.background,
              decoration: const InputDecoration(
                icon: Icon(Icons.numbers),
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
            ),
            ElevatedButton(
              onPressed: () {
                String emptyPicture = '';
                RewardsModel newRewards = RewardsModel(
                  _titleController.text,
                  startDate,
                  endDate,
                  _firstPrizeController.text,
                  _secondPrizeController.text,
                  _thirdPrizeController.text,
                  emptyPicture,
                );
                rewardsBox.add(newRewards);
                String toastMessage = 'Goal Added!';
                showToastMessage(context, toastMessage);
                goToHomeScreen(context);
              },
              // padding: const EdgeInsets.only(left: 30, right: 30, top: 15, bottom: 15),
              // color: Colors.pink,
              child: const Text(
                'Add Goal',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6),
              ),
            ),
          ],
        ),
      ),
      onWillPop: () async {
        if (activityBox.values.isEmpty) {
          goToHomeScreen(context);
          return true;
        }

        goToGoalsListScreen(context);
        return true;
      },
    );
  }
}
