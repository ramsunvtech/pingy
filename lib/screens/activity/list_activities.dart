import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pingy/models/hive/activity.dart';
import 'package:pingy/models/hive/activity_item.dart';
import 'package:pingy/screens/activity/update_activity.dart';
import 'package:pingy/screens/settings.dart';

import 'package:pingy/widgets/icons/settings.dart';

import 'package:pingy/widgets/FutureWidgets.dart';

import '../../utils/navigators.dart';

class ActivitiesListScreen extends StatefulWidget {
  @override
  _ActivitiesListScreenState createState() => _ActivitiesListScreenState();
}

class _ActivitiesListScreenState extends State<ActivitiesListScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  late final Box activityBox;
  late final Box activityTypeBox;

  set activityTypeDetail(activityTypeDetail) {}

  @override
  void initState() {
    super.initState();
    print('init state called');
    // Get reference to an already opened box
    activityBox = Hive.box('activity');
    activityTypeBox = Hive.box('activity_type');
  }

  Widget getListTileTrailingIconButton(String activityId) {
    var today = DateTime.now();
    var todayActivityId = 'activity_${today.year}${today.month}${today.day}';

    if (activityId != todayActivityId) {
      return IconButton(
        onPressed: () {
          goToPastActivityEditScreen(context, activityId);
        },
        icon: const Icon(
          Icons.edit,
          color: Colors.red,
        ),
      );
    }

    return IconButton(
      onPressed: () {
        activityBox.delete(activityId);
        String toastMessage = 'Activity removed successfully!';
        showToastMessage(context, toastMessage);
      },
      icon: const Icon(
        Icons.delete,
        color: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pingy (Activities)'),
          automaticallyImplyLeading: false,
          actions: [
            settingsLinkIconButton(context),
          ],
        ),
        body: ValueListenableBuilder(
          valueListenable: activityBox.listenable(),
          builder: (context, Box activityDataBox, widget) {
            if (activityDataBox.isEmpty) {
              return const Center(
                child: Text('No Activities are available.'),
              );
            } else {
              Iterable activityDataKeyList = activityDataBox.keys.toList().reversed;
              // TODO: fix the manual key index.
              int keyIndex = 0;
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
                  itemCount: activityDataKeyList.length,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    String activityId = activityDataKeyList.elementAt(keyIndex);
                    Activity activityData = activityDataBox.get(activityId);
                    keyIndex++;
                    Map activityTypeBoxMap = activityTypeBox.toMap();
                    Iterable<dynamic> activityTypeBoxMapValues =
                        activityTypeBoxMap.values;

                    // Activity Total Score.
                    dynamic activityTypeFullScore = 0;
                    activityTypeBoxMap.forEach((key, value) {
                      activityTypeFullScore += int.tryParse(value.fullScore)!;
                    });

                    dynamic dayScore = 0;
                    String missedItemsCSV = '';
                    if (activityData.activityItems.isNotEmpty) {
                      activityData.activityItems.forEach((element) {
                        var scoreValue = int.tryParse(element.score ?? "0");

                        if (scoreValue != null) {
                          dayScore += scoreValue;
                        }
                      });

                      Iterable<ActivityItem> missedActivityIdList = activityData
                          .activityItems
                          .where((element) => element.score == "0");
                      if (missedActivityIdList.isNotEmpty) {
                        List activityTypes = [];

                        for (var activityItem in missedActivityIdList) {
                          dynamic activityTypeDetail =
                              activityTypeBox.get(activityItem.activityItemId);
                          activityTypes.add(activityTypeDetail.activityName);
                        }

                        missedItemsCSV = 'Missed: \n${activityTypes.join('\n')}';
                      }
                    }

                    dynamic activityScoreValue =
                        (((dayScore / activityTypeFullScore) * 100).ceil());

                    String formattedDate = '';
                    if (activityData!.activityDate != null) {
                      DateFormat dateFormat = DateFormat("EEE, dd/MMM/yy");
                      formattedDate =
                          '(${dateFormat.format(activityData!.activityDate as DateTime)})';
                    }

                    return InkWell(
                      onTap: () => {},
                      child: ListTile(
                        title: Text(
                            'Activity $formattedDate - $activityScoreValue%'),
                        subtitle: Text(
                          'Score: $dayScore/$activityTypeFullScore\n'
                          '$missedItemsCSV',
                        ),
                        trailing: getListTileTrailingIconButton(
                            activityData.activityId),
                      ),
                    );
                  },
                ),
              );
            }
          },
        ),
      ),
      onWillPop: () async {
        goToSettingScreen(context);
        return true;
      },
    );
  }
}
