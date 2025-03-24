import 'package:flutter/material.dart';

Future<bool?> showConfirmDialog(BuildContext context, String title, String content) async {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("ยกเลิก"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("ตกลง"),
          ),
        ],
      );
    },
  );
}
