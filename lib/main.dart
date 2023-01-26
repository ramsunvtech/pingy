import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pingy/models/activity.dart';
import 'package:pingy/models/activity_type.dart';

// Screen Imports.
import 'screens/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDocDir = await getApplicationDocumentsDirectory();

  // Initialize hive.
  await Hive.initFlutter();

  // Register Adapters.
  Hive
    ..init(appDocDir.path)
    ..registerAdapter(ActivityAdapter())
    ..registerAdapter(ActivityTypeModelAdapter());

  // Open Activity, Activity Type Box.
  await Hive.openBox('activity');
  await Hive.openBox('activity_type');

  runApp(
    PingyApp(),
  );
}

class PingyApp extends StatefulWidget {
  @override
  _PingyAppState createState() => _PingyAppState();
}

class _PingyAppState extends State<PingyApp> {
  @override
  void dispose() {
    // Closes all Hive boxes
    Hive.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

// Text('Hello Pingy Rewards')
// PingyApp
