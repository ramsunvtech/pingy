import 'package:flutter/material.dart';

import 'package:pingy/screens/settings.dart';

import 'package:pingy/utils/navigators.dart';

Widget settingsLinkIconButton(BuildContext context) {
  return IconButton(
    icon: const Icon(
      Icons.settings,
      color: Colors.white,
    ),
    onPressed: () {
      goToSettingScreen(context);
    },
  );
}