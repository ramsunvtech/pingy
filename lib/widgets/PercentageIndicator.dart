import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import 'package:pingy/utils/color.dart';

dynamic percentageIndicator(double radius, String score, String label) {
  double percentValue = (int.tryParse(score ?? '0')! / 100);

  return Padding(
    padding: const EdgeInsets.only(left: 45.0, top: 20, bottom: 10),
    child: CircularPercentIndicator(
      radius: radius,
      lineWidth: 13.0,
      animation: true,
      percent: percentValue,
      center: Text(
        '$score%',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
      ),
      footer: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
        ),
      ),
      circularStrokeCap: CircularStrokeCap.round,
      progressColor: totalScoreColor,
    ),
  );
}
