import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pingy/models/hive/rewards.dart';
import 'package:pingy/screens/rewards/goals.dart';
import 'package:pingy/screens/settings.dart';
import 'package:pingy/utils/navigators.dart';

import 'package:pingy/widgets/icons/settings.dart';

class RewardsListScreen extends StatefulWidget {
  @override
  _RewardsListScreenState createState() => _RewardsListScreenState();
}

class _RewardsListScreenState extends State<RewardsListScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  late final Box rewardsBox;

  @override
  void initState() {
    super.initState();
    // Get reference to an already opened box
    rewardsBox = Hive.box('rewards');
  }

  Widget getFloatingButton(BuildContext context) {
    if (rewardsBox.isEmpty) {
      return Container();
    } else if (rewardsBox.isNotEmpty) {
      RewardsModel latestGoal = rewardsBox.values.last;
      List endPeriod = latestGoal.endPeriod.split('/').toList();

      DateTime today = DateTime.now();
      DateTime endDate =
          DateTime.parse('${endPeriod[2]}-${endPeriod[1]}-${endPeriod[0]}');
      Duration diff = endDate.difference(today);

      if (diff.inDays > 0) {
        return Container();
      }
    }

    return FloatingActionButton(
      onPressed: () {
        goToGoalsForm(context);
      },
      backgroundColor: const Color(0xFF98006D),
      child: const Icon(Icons.add),
    );
  }

  String getPrize(String prize) {
    return (prize == '') ? 'Not Mentioned' : prize;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pingy (Goals)'),
          automaticallyImplyLeading: false,
          actions: [
            settingsLinkIconButton(context),
          ],
        ),
        body: ValueListenableBuilder(
          valueListenable: rewardsBox.listenable(),
          builder: (context, Box box, widget) {
            if (box.isEmpty) {
              return const Center(
                child: Text('No Goals are available.'),
              );
            } else {
              return RefreshIndicator(
                key: _refreshIndicatorKey,
                color: Colors.white,
                backgroundColor: Colors.blue,
                strokeWidth: 4.0,
                onRefresh: () async {
                  // Replace this delay with the code to be executed during refresh
                  // and return a Future when code finish execution.
                  return Future<void>.delayed(const Duration(seconds: 3));
                },
                // Pull from top to show refresh indicator.
                child: ListView.builder(
                  itemCount: rewardsBox.length,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    var currentBox = rewardsBox;
                    RewardsModel rewardsData = currentBox.getAt(index)!;
                    return InkWell(
                      onTap: () => {},
                      child: ListTile(
                        title: Text(rewardsData.title),
                        subtitle: Text('${rewardsData.startPeriod}'
                            ' to ${rewardsData.endPeriod}\n'
                            'First Prize (95%): ${getPrize(rewardsData.firstPrice)}\n'
                            'Second Prize (85%): ${getPrize(rewardsData.secondPrice)}\n'
                            'Third Prize (75%): ${getPrize(rewardsData.thirdPrice)}'),
                      ),
                    );
                  },
                ),
              );
            }
          },
        ),
        floatingActionButton: getFloatingButton(context),
      ),
      onWillPop: () async {
        goToSettingScreen(context);
        return true;
      },
    );
  }
}
