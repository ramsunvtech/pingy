import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pingy/screens/activity/activity_type.dart';
import 'package:pingy/screens/settings.dart';
import 'package:pingy/utils/navigators.dart';

import 'package:pingy/widgets/icons/settings.dart';

class ActivityTypeListScreen extends StatefulWidget {
  @override
  _ActivityTypeListScreenState createState() => _ActivityTypeListScreenState();
}

class _ActivityTypeListScreenState extends State<ActivityTypeListScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  late final Box activityTypeBox;
  late final Box activityBox;

  String activityTypeCount = '0';

  @override
  void initState() {
    super.initState();
    // Get reference to an already opened box
    activityBox = Hive.box('activity');
    activityTypeBox = Hive.box('activity_type');

    if (activityTypeBox.isNotEmpty) {
      activityTypeCount = activityTypeBox.length.toString();
    }
  }

  Widget getFloatingActionButton() {
    if (activityBox.isNotEmpty) {
      return Container();
    }

    return FloatingActionButton(
      onPressed: () {
        goToActivityTypeFormScreen(context);
      },
      backgroundColor: const Color(0xFF98006D),
      child: const Icon(Icons.add),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: Scaffold(
          appBar: AppBar(
            title: Text('Activity Types - ($activityTypeCount)'),
            automaticallyImplyLeading: false,
            actions: [
              settingsLinkIconButton(context),
            ],
          ),
          body: ValueListenableBuilder(
            valueListenable: activityTypeBox.listenable(),
            builder: (context, Box box, widget) {
              if (box.isEmpty) {
                return const Center(
                  child: Text('Add your first Activity Type and have Fun!'),
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
                    itemCount: activityTypeBox.length,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      var currentBox = activityTypeBox;
                      var activityTypeData = currentBox.getAt(index)!;
                      return InkWell(
                        onTap: () => {},
                        child: ListTile(
                          title: Text(activityTypeData.activityName),
                          subtitle: Text(activityTypeData.fullScore),
                        ),
                      );
                    },
                  ),
                );
              }
            },
          ),
          floatingActionButton: getFloatingActionButton(),
        ),
        onWillPop: () async {
          goToSettingScreen(context);
          return true;
        });
  }
}
