import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import 'package:pingy/utils/color.dart';

dynamic percentageIndicator(double radius, String score, String label) {
  double percentValue = 0;
  String displayScore = "0"; // Default display value

  if (int.tryParse(score) != null) {
    displayScore = score;
    percentValue = int.tryParse(score)! / 100;
  }

  // TODO - this line need to be removed later.
  if (percentValue > 1) {
    percentValue = 1.0;
  }

  return Padding(
    padding: const EdgeInsets.only(left: 20, top: 20, bottom: 10, right: 20),
    child: CircularPercentIndicator(
      radius: radius,
      lineWidth: 13.0,
      animation: true,
      animationDuration: 1600,
      percent: percentValue,
      center: Text(
        '$displayScore%',
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
