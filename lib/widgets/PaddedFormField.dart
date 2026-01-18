import 'package:flutter/material.dart';

Widget paddedFormField(Widget childWidget,
    {double leftPadding = 16.0, double rightPadding = 16.0}) {
  return Padding(
      padding: EdgeInsets.only(left: leftPadding, right: rightPadding),
      child: childWidget);
}
