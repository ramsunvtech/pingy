import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pingy/utils/navigators.dart';

import 'package:pingy/widgets/SettingsBottomNavigation.dart';
import 'package:pingy/widgets/CustomAppBar.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final Box rewardBox;
  late final Box activityBox;
  late final Box activityTypeBox;

  String rewardExist = 'No';
  String activityCount = '0';
  String activityTypeCount = '0';

  final auth = LocalAuthentication();
  String authorized = " not authorized";
  bool _canCheckBiometric = false;
  late List<BiometricType> _availableBiometric;

  Future<void> _authenticate() async {
    bool authenticated = false;

    if (!kIsWeb) {
      try {
        authenticated = await auth.authenticate(
            localizedReason: "Scan your finger to authenticate");
      } on PlatformException catch (e) {
        // print('platform exception');
        // print(e);
      }
    }

    setState(() {
      authorized =
          authenticated ? "Authorized success" : "Failed to authenticate";
    });
  }

  Future<bool> _showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must choose Yes / No
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _checkBiometric() async {
    bool canCheckBiometric = false;

    if (!kIsWeb) {
      try {
        canCheckBiometric = await auth.canCheckBiometrics;
      } on PlatformException catch (e) {
        // print(e);
      }

      if (!mounted) return;

      setState(() {
        _canCheckBiometric = canCheckBiometric;
      });
    }
  }

  Future _getAvailableBiometric() async {
    List<BiometricType> availableBiometric = [];

    try {
      availableBiometric = await auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      // print(e);
    }

    setState(() {
      _availableBiometric = availableBiometric;
    });
  }

  @override
  void initState() {
    _checkBiometric();
    _getAvailableBiometric();
    super.initState();

    rewardBox = Hive.box('rewards');
    activityBox = Hive.box('activity');
    activityTypeBox = Hive.box('activity_type');

    if (rewardBox.isNotEmpty) {
      rewardExist = '';
    }

    if (activityBox.isNotEmpty) {
      activityCount = activityBox.length.toString();
    }

    if (activityTypeBox.isNotEmpty) {
      activityTypeCount = activityTypeBox.length.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: customAppBar(
          title: 'Settings',
          leading: GestureDetector(
            onTap: () {
              goToHomeScreen(context);
            },
            child: const Icon(
              Icons.home_rounded, // add custom icons also
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$rewardExist Goal exist',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.blue,
                  ),
                ),
                Center(
                  child: Text(
                    '$activityCount Activity added!',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.blue,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '$activityTypeCount Activity Types added!',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.blue,
                    ),
                  ),
                ),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      final confirmed = await _showConfirmDialog(
                        context: context,
                        title: 'Clear Activity Scores',
                        message:
                            'Are you sure you want to delete all activities?',
                      );

                      if (!confirmed) return;

                      await activityBox.clear();

                      setState(() {
                        activityCount = '0';
                      });
                    },
                    child: const Text(
                      'Clear all Activity Scores',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      final confirmed = await _showConfirmDialog(
                        context: context,
                        title: 'Clear Activity',
                        message:
                            'This will remove all activity types. Continue?',
                      );

                      if (!confirmed) return;

                      await activityTypeBox.clear();

                      setState(() {
                        activityTypeCount = '0';
                      });
                    },
                    child: const Text(
                      'Clear all Activities',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      final confirmed = await _showConfirmDialog(
                        context: context,
                        title: 'Clear Everything',
                        message:
                            'This will permanently delete goals, activities, and activity types.\n\nAre you absolutely sure?',
                      );

                      if (!confirmed) return;

                      await rewardBox.clear();
                      await activityTypeBox.clear();
                      await activityBox.clear();

                      setState(() {
                        rewardExist = 'No';
                        activityCount = '0';
                        activityTypeCount = '0';
                      });
                    },
                    child: const Text(
                      'Clear All',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                // Center(
                //   child: Text(authorized),
                // ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: settingsBottomNavigationBar(context),
      ),
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        goToHomeScreen(context);
        return;
      },
    );
  }
}
