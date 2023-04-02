import 'package:flutter/material.dart';

import 'package:pingy/utils/navigators.dart';

BottomNavigationBar settingsBottomNavigationBar(BuildContext context) {
  return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_walk_outlined),
          label: 'Activities',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.flag_outlined),
          label: 'Goal',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.military_tech),
          label: 'Scores',
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
