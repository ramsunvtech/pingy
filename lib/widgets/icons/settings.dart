import 'package:flutter/material.dart';

import 'package:pingy/screens/settings.dart';
import 'package:pingy/utils/navigators.dart';
import 'package:pingy/utils/color.dart';

Widget settingsLinkIconButton(BuildContext context) {
  return IconButton(
    icon: Icon(
      Icons.settings,
      color: iconColor,
    ),
    onPressed: () {
      goToSettingScreen(context);
    },
  );
}