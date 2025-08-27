import 'package:flutter/material.dart';

Future<bool> showExitConfirmationDialog(BuildContext context) async {
  // Dismiss keyboard if focused
  FocusScope.of(context).unfocus();

  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.pinkAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: const [
            Icon(Icons.exit_to_app, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Keluar Aplikasi?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: const Text(
          'Apakah kamu yakin ingin keluar dari aplikasi?',
          style: TextStyle(color: Colors.white, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.pinkAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Keluar'),
          ),
        ],
      );
    },
  );

  return result ?? false;
}
