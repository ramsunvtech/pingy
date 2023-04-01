import 'package:flutter/material.dart';

import 'package:pingy/utils/color.dart';

Widget greyCard(Widget leftBlock, Widget rightBlock) {
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
          leftBlock,
          rightBlock,
        ],
      )
    ),
  );
}


// SizedBox(
// width: 300,
// height: 100,
// child: Center(child: Text('Outlined Card')),
// ),