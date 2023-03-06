import 'package:flutter/material.dart';

import 'package:pingy/screens/activity/list_activity_type.dart';
import 'package:pingy/screens/activity/list_activities.dart';
import 'package:pingy/screens/home.dart';
import 'package:pingy/screens/rewards/list_rewards.dart';
import 'package:pingy/screens/settings.dart';

void goToActivityTypeListScreen(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (builder) => ActivityTypeListScreen(),
    ),
  );
}

void goToGoalsListScreen(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (builder) => RewardsListScreen(),
    ),
  );
}

void goToActivityListScreen(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (builder) => ActivitiesListScreen(),
    ),
  );
}

void goToHomeScreen(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (builder) => HomeScreen(),
    ),
  );
}

void goToSettingScreen(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (builder) => SettingsScreen(),
    ),
  );
}