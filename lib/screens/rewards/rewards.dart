import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:pingy/models/rewards.dart';
import 'package:pingy/screens/rewards/list_rewards.dart';

class RewardsScreen extends StatefulWidget {
  @override
  _RewardsScreenState createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final TextEditingController _titleController = TextEditingController();
  // DateTime _startPeriodController = DateTime.now();
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

  // Future<void> _selectDate(BuildContext context) async {
  //   final DateTime picked = await showDatePicker(
  //       context: context,
  //       initialDate: selectedDate,
  //       firstDate: DateTime(2015, 8),
  //       lastDate: DateTime(2101));
  //   if (picked != null && picked != selectedDate)
  //     setState(() {
  //       selectedDate = picked;
  //     });
  // }

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
                labelText: 'Start Period',
                labelStyle: TextStyle(
                  color: Color(0xFF6200EE),
                ),
                helperText: const (_startPeriodController.text != '') ? 'Choose starting period' : '',
                suffixIcon: Icon(
                  Icons.calendar_month,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6200EE)),
                ),
              ),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(), //get today's date
                      firstDate:DateTime(2000), //DateTime.now() - not to allow to choose before today.
                      lastDate: DateTime(2101)
                  );
                  if(pickedDate != null ){
                    print(pickedDate);  //get the picked date in the format => 2022-07-04 00:00:00.000
                    String formattedDate = DateFormat('dd-MM-yyyy').format(pickedDate); // format date in required form here we use yyyy-MM-dd that means time is removed

                    setState(() {
                      _startPeriodController.text = formattedDate; //set foratted date to TextField value.
                    });
                  }else{
                    print("Date is not selected");
                  }
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
