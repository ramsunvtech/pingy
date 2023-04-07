import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:pingy/utils/color.dart';

AppBar customAppBar({
  String title = '',
  List<Widget>? actions,
  Widget? leading,
  bool automaticallyImplyLeading = false,
  double elevation = 0,
  Color backgroundColor = Colors.white,
  Color foregroundColor = iconColor,
  PreferredSizeWidget? bottom,
}) {
  return AppBar(
    title: Text(title),
    actions: actions,
    leading: leading,
    automaticallyImplyLeading: automaticallyImplyLeading,
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
    elevation: elevation,
    bottom: bottom,
  );
}
