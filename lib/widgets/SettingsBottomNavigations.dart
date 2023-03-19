import 'package:flutter/material.dart';

import 'package:pingy/utils/navigators.dart';

BottomNavigationBar settingsBottomNavigationBar(BuildContext context) {
  return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.add_task_sharp),
          label: 'Activity Types',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add),
          label: 'Goal',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add),
          label: 'Activities',
        ),
      ],
      onTap: (int index) {
        switch (index) {
          case 0:
            goToActivityTypeListScreen(context);
            break;
          case 1:
            goToGoalsListScreen(context);
            break;
          case 2:
            goToActivityListScreen(context);
            break;
        }
      });
}
