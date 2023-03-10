import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

Future showToast(String message) async {
  if (message.isNotEmpty) {
    return await Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
  }
}
