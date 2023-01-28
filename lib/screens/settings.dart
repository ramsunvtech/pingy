import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pingy/screens/rewards/rewards.dart';
import 'package:pingy/screens/task/list_activities.dart';
import 'package:pingy/screens/task/list_activity_type.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final auth = LocalAuthentication();
  String authorized = " not authorized";
  bool _canCheckBiometric = false;
  late List<BiometricType> _availableBiometric;

  Future<void> _authenticate() async {
    bool authenticated = false;

    if (kIsWeb) {
      try {
        authenticated = await auth.authenticate(
            localizedReason: "Scan your finger to authenticate");
      } on PlatformException catch (e) {
        print(e);
      }
    }

    setState(() {
      authorized =
          authenticated ? "Authorized success" : "Failed to authenticate";
    });
  }

  Future<void> _checkBiometric() async {
    bool canCheckBiometric = false;

    try {
      canCheckBiometric = await auth.canCheckBiometrics;
    } on PlatformException catch (e) {
      print(e);
    }

    if (!mounted) return;

    setState(() {
      _canCheckBiometric = canCheckBiometric;
    });
  }

  Future _getAvailableBiometric() async {
    List<BiometricType> availableBiometric = [];

    try {
      availableBiometric = await auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      print(e);
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pingy (Settings)')),
      body: SafeArea(
        child: Column(
          children: [
            Center(
              child: ElevatedButton.icon(
                onPressed: _authenticate,
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Fingerprint Auth"),
              ),
            ),
            Center(
              child: Text(authorized),
            )
          ],
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
              label: 'Rewards',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add),
              label: 'Activities',
            ),
          ],
          onTap: (int index) {
            switch (index) {
              case 0:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (builder) => ActivityTypeListScreen(),
                  ),
                );
                break;
              case 1:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (builder) => RewardsListScreen(),
                  ),
                );
                break;
              case 2:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (builder) => ActivitiesListScreen(),
                  ),
                );
                break;
            }
          }),
    );
  }
}
