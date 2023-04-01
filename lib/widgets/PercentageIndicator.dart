import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import 'package:pingy/utils/color.dart';

dynamic percentageIndicator(double radius, String score, String label) {
  double percentValue = (int.tryParse(score ?? '0')! / 100);

  return Padding(
    padding: const EdgeInsets.only(left: 16.0, top: 10, bottom: 10),
    child: CircularPercentIndicator(
      radius: radius,
      lineWidth: 13.0,
      animation: true,
      percent: percentValue,
      center: Text(
        '$score%',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
      ),
      footer: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17.0),
      ),
      circularStrokeCap: CircularStrokeCap.round,
      progressColor: totalScoreColor,
    ),
  );
}
