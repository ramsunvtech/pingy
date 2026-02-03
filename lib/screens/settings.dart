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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
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

  void _showSnackBar(String message, {bool isSuccess = true}) {
    if (!mounted) return;
    
    // CRITICAL: Clear any existing snackbars first
    ScaffoldMessenger.of(context).clearSnackBars();
    
    // Show the snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.info,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? Colors.green.shade600 : Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        elevation: 4,
      ),
    );
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback onPressed,
    required IconData icon,
    bool destructive = false,
  }) {
    final color = destructive ? Colors.red.shade600 : Colors.blue.shade600;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: destructive 
                  ? Colors.red.shade50 
                  : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: color.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: customAppBar(
          title: 'Settings',
          leading: IconButton(
            icon: const Icon(Icons.home_rounded),
            onPressed: () => goToHomeScreen(context),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            // Stats section
            _buildSectionTitle("Overview"),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildStatCard(
                    label: "Goals Status",
                    value: rewardExist.isEmpty ? "Active" : "None",
                    icon: Icons.emoji_events_rounded,
                    color: rewardExist.isEmpty
                        ? Colors.amber.shade700
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    label: "Activities Logged",
                    value: activityCount,
                    icon: Icons.timeline_rounded,
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    label: "Activity Types",
                    value: activityTypeCount,
                    icon: Icons.category_rounded,
                    color: Colors.purple.shade600,
                  ),
                ],
              ),
            ),

            // Notifications section
            _buildSectionTitle("Notifications"),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  title: const Text(
                    "Ongoing Notifications",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    "Show persistent notification for active goals",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  value: enableOngoingNotification,
                  activeColor: Colors.blue.shade600,
                  onChanged: (value) async {
                    print('🔔 Toggle changed to: $value');
                    
                    // Update UI immediately
                    setState(() {
                      enableOngoingNotification = value;
                    });

                    // Save to Hive
                    try {
                      await settingsBox.put(
                        'enable_ongoing_notification',
                        SettingsModel(
                          settingKey: 'enable_ongoing_notification',
                          value: value,
                        ),
                      );
                      print('✅ Setting saved to Hive');
                    } catch (e) {
                      print('❌ Error saving to Hive: $e');
                    }

                    // Show toast AFTER saving
                    _showSnackBar(
                      value
                          ? "Ongoing notifications enabled"
                          : "Ongoing notifications disabled",
                    );
                    
                    print('✅ Toast shown');
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            // Data actions section
            _buildSectionTitle("Data Management"),
            _buildActionButton(
              text: "Clear Activity Scores",
              icon: Icons.delete_sweep_rounded,
              onPressed: () async {
                final confirmed = await _showConfirmDialog(
                  context: context,
                  title: "Clear Activity Scores",
                  message: "Are you sure you want to delete all activities?",
                );
                if (!confirmed) return;

                await activityBox.clear();
                setState(() => activityCount = '0');
                _showSnackBar("Activity scores cleared");
              },
            ),
            _buildActionButton(
              text: "Clear Activity Types",
              icon: Icons.layers_clear_rounded,
              onPressed: () async {
                final confirmed = await _showConfirmDialog(
                  context: context,
                  title: "Clear Activity Types",
                  message: "This will remove all activity types. Continue?",
                );
                if (!confirmed) return;

                await activityTypeBox.clear();
                setState(() => activityTypeCount = '0');
                _showSnackBar("Activity types cleared");
              },
            ),
            _buildActionButton(
              text: "Clear All Data",
              icon: Icons.warning_rounded,
              destructive: true,
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
                _showSnackBar("All data cleared");
              },
            ),
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