import 'package:flutter/material.dart';

Widget greyCard(Widget leftBlock, Widget rightBlock) {
  return Center(
    child: Card(

      elevation: 0,
      shape: const RoundedRectangleBorder(
        side: BorderSide(
          color: Colors.grey,
        ),
        borderRadius: BorderRadius.all(Radius.circular(16)),
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