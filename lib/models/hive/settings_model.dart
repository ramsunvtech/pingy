import 'package:hive/hive.dart';

part 'settings_model.g.dart';

@HiveType(typeId: 10)
class SettingsModel extends HiveObject {
  @HiveField(0)
  final String settingKey;

  @HiveField(1)
  final Object? value;

  SettingsModel({
    required this.settingKey,
    required this.value,
  });
}
