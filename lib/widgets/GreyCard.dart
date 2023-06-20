import 'package:flutter/material.dart';

import 'package:pingy/utils/color.dart';

Widget twoColumnGreyCards(Widget leftBlock, Widget rightBlock) {
  return Center(
    child: Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: greyColor,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Align(
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              leftBlock,
              rightBlock,
            ],
          ),
        ),
      )
    ),
  );
}

Widget greyCard(Widget blockContent) {
  return Center(
    child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: greyColor,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(16)),
        ),
        child: Row(
          children: [
            blockContent
          ],
        )
    ),
  );
}
