import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:pingy/models/hive/rewards.dart';
import 'package:pingy/screens/rewards/list_rewards.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class RewardsScreen extends StatefulWidget {
  @override
  _RewardsScreenState createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _startPeriodController = TextEditingController();
  final TextEditingController _endPeriodController = TextEditingController();
  final TextEditingController _firstPrizeController = TextEditingController();
  final TextEditingController _secondPrizeController = TextEditingController();
  final TextEditingController _thirdPrizeController = TextEditingController();

  late final Box rewardsBox;

  @override
  void initState() {
    super.initState();
    // Get reference to an already opened box
    rewardsBox = Hive.box('rewards');
  }

  @override
  void dispose() {
    // Close Hive Connection.
    // Hive.close();

    super.dispose();
  }

  String _selectedDate = '';
  String _dateCount = '';
  String _range = '';
  String _rangeCount = '';

  void _onSelectionChanged(DateRangePickerSelectionChangedArgs args) {
    setState(() {
      if (args.value is PickerDateRange) {
        _range = '${DateFormat('dd/MM/yyyy').format(args.value.startDate)} -'
        // ignore: lines_longer_than_80_chars
            ' ${DateFormat('dd/MM/yyyy').format(args.value.endDate ?? args.value.startDate)}';
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
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Pingy (Add Rewards)')),
      body: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: _titleController,
              cursorColor: Theme.of(context).backgroundColor,
              decoration: const InputDecoration(
                icon: Icon(Icons.label),
                labelText: 'Rewards Title',
                labelStyle: TextStyle(
                  color: Color(0xFF6200EE),
                ),
                helperText: 'Enter your rewards title',
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
              cursorColor: Theme.of(context).backgroundColor,
              readOnly: true,
              decoration: const InputDecoration(
                icon: Icon(Icons.calendar_today),
                labelText: 'Start Date',
                labelStyle: TextStyle(
                  color: Color(0xFF6200EE),
                ),
                helperText: 'Choose starting period',
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
                            selectionMode: DateRangePickerSelectionMode.range,
                            initialSelectedRange: PickerDateRange(
                                DateTime.now().subtract(const Duration(days: 4)),
                                DateTime.now().add(const Duration(days: 3))),
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
                            )
                          ),
                        ],
                      );
                    },
                  );
                },
            ),
            TextFormField(
              controller: _endPeriodController,
              cursorColor: Theme.of(context).backgroundColor,
              keyboardType: TextInputType.number,
              maxLength: 10,
              decoration: const InputDecoration(
                icon: Icon(Icons.numbers),
                labelText: 'End Period',
                labelStyle: TextStyle(
                  color: Color(0xFF6200EE),
                ),
                helperText: 'Choose ending period',
                suffixIcon: Icon(
                  Icons.calendar_month,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6200EE)),
                ),
              ),
            ),
            TextFormField(
              controller: _firstPrizeController,
              cursorColor: Theme.of(context).backgroundColor,
              decoration: const InputDecoration(
                icon: Icon(Icons.numbers),
                labelText: '1st Prize',
                labelStyle: TextStyle(
                  color: Color(0xFF6200EE),
                ),
                helperText: 'Enter First Prize',
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
              cursorColor: Theme.of(context).backgroundColor,
              decoration: const InputDecoration(
                icon: Icon(Icons.numbers),
                labelText: '2nd Prize',
                labelStyle: TextStyle(
                  color: Color(0xFF6200EE),
                ),
                helperText: 'Enter Second Prize',
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
              cursorColor: Theme.of(context).backgroundColor,
              decoration: const InputDecoration(
                icon: Icon(Icons.numbers),
                labelText: '3rd Prize',
                labelStyle: TextStyle(
                  color: Color(0xFF6200EE),
                ),
                helperText: 'Enter Third Prize',
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
                RewardsModel newRewards = RewardsModel(
                  _titleController.text,
                  _startPeriodController.text,
                  _endPeriodController.text,
                  _firstPrizeController.text,
                  _secondPrizeController.text,
                  _thirdPrizeController.text,
                );
                rewardsBox.add(newRewards);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (builder) => RewardsListScreen(),
                  ),
                );
              },
              // padding: const EdgeInsets.only(left: 30, right: 30, top: 15, bottom: 15),
              // color: Colors.pink,
              child: const Text(
                'Add Rewards',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
