import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pingy/models/hive/rewards.dart';
import 'package:pingy/screens/rewards/rewards.dart';

class RewardsListScreen extends StatefulWidget {
  @override
  _RewardsListScreenState createState() => _RewardsListScreenState();
}

class _RewardsListScreenState extends State<RewardsListScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  late final Box rewardsBox;

  @override
  void initState() {
    super.initState();
    // Get reference to an already opened box
    rewardsBox = Hive.box('rewards');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pingy (Rewards)'),
      ),
      body: ValueListenableBuilder(
        valueListenable: rewardsBox.listenable(),
        builder: (context, Box box, widget) {
          if (box.isEmpty) {
            return const Center(
              child: Text('No Rewards are available.'),
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
                      subtitle: Text(
                          '${rewardsData.startPeriod}'
                          ' to ${rewardsData.endPeriod}\n'
                          'First Prize: ${rewardsData.firstPrice}\n'
                          'Second Prize: ${rewardsData.secondPrice}\n'
                          'Third Prize: ${rewardsData.thirdPrice}'
                      ),
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (builder) => RewardsScreen(),
            ),
          );
        },
        child: const Icon(Icons.gif_box),
        backgroundColor: Colors.green,
      ),
    );
  }
}
