import 'package:flutter/material.dart';

import 'package:pingy/screens/activity/list_activity_type.dart';
import 'package:pingy/screens/activity/list_activities.dart';
import 'package:pingy/screens/home.dart';
import 'package:pingy/screens/goals/list_goals.dart';
import 'package:pingy/screens/goals/goal_status.dart';
import 'package:pingy/screens/settings.dart';
import 'package:pingy/screens/activity/update_activity.dart';
import 'package:pingy/screens/goals/goals.dart';
import 'package:pingy/screens/activity/activity_type.dart';

void goToActivityTypeListScreen(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (builder) => ActivityTypeListScreen(),
    ),
  );
}

void goToActivityTypeFormScreen(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (builder) => const TaskTypeScreen(),
    ),
  );
}

void goToGoalsListScreen(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (builder) => GoalListScreen(),
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

/// Navigate back to home screen (pops until we reach home)
void goToHomeScreen(BuildContext context) {
  // Pop back to the first route (home screen)
  Navigator.of(context).popUntil((route) => route.isFirst);
}

void goToHomeScreenV2(BuildContext context) {
  Navigator.of(context).pushNamedAndRemoveUntil(
    '/home',
    (route) => false,
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

void goToActivityTypeEditScreen(BuildContext context, String activityTypeId) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (builder) => TaskTypeScreen(activityTypeId: activityTypeId),
    ),
  );
}

void goToPastActivityEditScreen(BuildContext context, String activityTypeId) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (builder) => UpdateTaskScreen(activityId: activityTypeId),
    ),
  );
}

void goToUpdateActivityScreen(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (builder) => const UpdateTaskScreen(),
    ),
  );
}

void goToGoalsForm(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (builder) => GoalScreen(),
    ),
  );
}

void goToGoalStatusScreen(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (builder) => GoalStatusScreen(),
    ),
  );
}

void goToGoalStatusScreenWithId(BuildContext context, String goalId) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (builder) => GoalStatusScreen(goalId: goalId),
    ),
  );
}