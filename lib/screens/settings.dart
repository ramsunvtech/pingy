import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pingy/utils/navigators.dart';

import 'package:pingy/widgets/SettingsBottomNavigation.dart';
import 'package:pingy/widgets/CustomAppBar.dart';
import 'package:pingy/models/hive/settings_model.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final Box rewardBox;
  late final Box activityBox;
  late final Box activityTypeBox;
  late final Box<SettingsModel> settingsBox;

  String rewardExist = 'No';
  String activityCount = '0';
  String activityTypeCount = '0';

  final auth = LocalAuthentication();
  String authorized = " not authorized";
  bool _canCheckBiometric = false;
  late List<BiometricType> _availableBiometric;

  // Hive-backed setting
  bool enableOngoingNotification = false;

  Future<void> _authenticate() async {
    bool authenticated = false;
    if (!kIsWeb) {
      try {
        authenticated = await auth.authenticate(
            localizedReason: "Scan your finger to authenticate");
      } on PlatformException catch (e) {}
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
      barrierDismissible: false,
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
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _checkBiometric() async {
    if (!kIsWeb) {
      try {
        _canCheckBiometric = await auth.canCheckBiometrics;
      } on PlatformException catch (e) {}
      if (!mounted) return;
      setState(() {});
    }
  }

  Future _getAvailableBiometric() async {
    try {
      _availableBiometric = await auth.getAvailableBiometrics();
    } on PlatformException catch (e) {}
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    _checkBiometric();
    _getAvailableBiometric();

    rewardBox = Hive.box('rewards');
    activityBox = Hive.box('activity');
    activityTypeBox = Hive.box('activity_type');
    settingsBox = Hive.box<SettingsModel>('settings');

    enableOngoingNotification =
        settingsBox.get('enable_ongoing_notification')?.value as bool? ?? false;

    if (rewardBox.isNotEmpty) rewardExist = '';
    if (activityBox.isNotEmpty) activityCount = activityBox.length.toString();
    if (activityTypeBox.isNotEmpty)
      activityTypeCount = activityTypeBox.length.toString();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
      ),
    );
  }

  Widget _buildActionButton(
      {required String text,
      required Color color,
      required VoidCallback onPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          minimumSize: const Size.fromHeight(50),
        ),
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: customAppBar(
          title: 'Settings',
          leading: IconButton(
            icon: const Icon(Icons.home_rounded),
            onPressed: () => goToHomeScreen(context),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            // Info section
            _buildSectionTitle("Current Stats"),
            ListTile(
              title: Text("Goals exist"),
              trailing: Text(rewardExist.isEmpty ? "Yes" : "No"),
            ),
            ListTile(
              title: Text("Activity added"),
              trailing: Text(activityCount),
            ),
            ListTile(
              title: Text("Activity Types added"),
              trailing: Text(activityTypeCount),
            ),
            const Divider(),

            // Notifications section
            _buildSectionTitle("Notifications"),
            SwitchListTile(
              title: const Text("Enable ongoing notification"),
              subtitle: const Text(
                  "Shows a persistent notification for active goals"),
              value: enableOngoingNotification,
              onChanged: (value) async {
                setState(() {
                  enableOngoingNotification = value;
                });

                await settingsBox.put(
                  'enable_ongoing_notification',
                  SettingsModel(
                    settingKey: 'enable_ongoing_notification', // ← required
                    value: value, // ← required
                  ),
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value
                          ? "Ongoing notifications enabled ✅"
                          : "Ongoing notifications disabled ❌",
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),

            const Divider(),

            // Data actions section
            _buildSectionTitle("Data Management"),
            _buildActionButton(
              text: "Clear all Activity Scores",
              color: Colors.redAccent,
              onPressed: () async {
                final confirmed = await _showConfirmDialog(
                  context: context,
                  title: "Clear Activity Scores",
                  message: "Are you sure you want to delete all activities?",
                );
                if (!confirmed) return;

                await activityBox.clear();
                setState(() => activityCount = '0');
              },
            ),
            _buildActionButton(
              text: "Clear all Activities",
              color: Colors.redAccent,
              onPressed: () async {
                final confirmed = await _showConfirmDialog(
                  context: context,
                  title: "Clear Activities",
                  message: "This will remove all activity types. Continue?",
                );
                if (!confirmed) return;

                await activityTypeBox.clear();
                setState(() => activityTypeCount = '0');
              },
            ),
            _buildActionButton(
              text: "Clear All Data",
              color: Colors.redAccent,
              onPressed: () async {
                final confirmed = await _showConfirmDialog(
                  context: context,
                  title: "Clear Everything",
                  message:
                      "This will permanently delete goals, activities, and activity types. Are you sure?",
                );
                if (!confirmed) return;

                await rewardBox.clear();
                await activityBox.clear();
                await activityTypeBox.clear();
                setState(() {
                  rewardExist = 'No';
                  activityCount = '0';
                  activityTypeCount = '0';
                });
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
        bottomNavigationBar: settingsBottomNavigationBar(context),
      ),
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        Navigator.pop(context);
        return;
      },
    );
  }
}
