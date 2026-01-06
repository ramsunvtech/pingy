import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pingy/models/hive/activity.dart';
import 'package:pingy/models/hive/activity_item.dart';

import 'package:pingy/widgets/icons/settings.dart';
import 'package:pingy/widgets/FutureWidgets.dart';
import 'package:pingy/widgets/SettingsBottomNavigation.dart';
import 'package:pingy/widgets/CustomAppBar.dart';

import 'package:pingy/utils/navigators.dart';

class ActivitiesListScreen extends StatefulWidget {
  @override
  _ActivitiesListScreenState createState() => _ActivitiesListScreenState();
}

class _ActivitiesListScreenState extends State<ActivitiesListScreen> {
  late final Box activityBox;
  late final Box activityTypeBox;

  String activityCount = '0';

  set activityTypeDetail(activityTypeDetail) {}

  @override
  void initState() {
    super.initState();
    // Get reference to an already opened box
    activityBox = Hive.box('activity');
    activityTypeBox = Hive.box('activity_type');

    if (activityBox.isNotEmpty) {
      activityCount = activityBox.length.toString();
    }
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
        String toastMessage = 'Score removed successfully!';
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
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: customAppBar(
          title: 'Scores ($activityCount days)',
          actions: [
            settingsLinkIconButton(context),
          ],
        ),
        body: ValueListenableBuilder(
          valueListenable: activityBox.listenable(),
          builder: (context, Box activityDataBox, widget) {
            if (activityDataBox.isEmpty) {
              return const Center(
                child: Text('No Scores are available.'),
              );
            } else {
              Iterable activityDataKeyList =
                  activityDataBox.keys.toList().reversed;
              // TODO: fix the manual key index.
              return ListView.builder(
                itemCount: activityDataKeyList.length,
                physics: const AlwaysScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  String activityId = activityDataKeyList.elementAt(index);
                  Activity activityData = activityDataBox.get(activityId);
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
              );
            }
          },
        ),
        bottomNavigationBar: settingsBottomNavigationBar(context),
      ),
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        goToSettingScreen(context);
        return;
      },
    );
  }
}
