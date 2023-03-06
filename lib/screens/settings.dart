import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pingy/screens/home.dart';
import 'package:pingy/screens/activity/list_activities.dart';
import 'package:pingy/utils/navigators.dart';

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
    return WillPopScope(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pingy (Settings)'),
          leading: GestureDetector(
            onTap: () {
              goToHomeScreen(context);
            },
            child: Icon(
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.blue,
                  ),
                ),
                Center(
                  child: Text(
                    '$activityCount Activity added!',
                    style: TextStyle(
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
                    style: TextStyle(
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
                      await rewardBox.clear();
                      await activityTypeBox.clear();
                      await activityBox.clear();
                      setState(() {
                        rewardExist = 'No';
                        activityCount = '0';
                        activityTypeCount = '0';

                        if (rewardBox.isNotEmpty) {
                          rewardExist = '';
                        }

                        if (activityBox.isNotEmpty) {
                          activityCount = activityBox.length.toString();
                        }

                        if (activityTypeBox.isNotEmpty) {
                          activityTypeCount = activityTypeBox.length.toString();
                        }
                      });
                    },
                    child: const Text(
                      'Clear Data',
                      style: TextStyle(
                        fontSize: 20,
                      ),
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
        bottomNavigationBar: BottomNavigationBar(
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
            }),
      ),
      onWillPop: () async {
        goToHomeScreen(context);
        return true;
      },
    );
  }
}
