import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TutorialDismissButton extends StatelessWidget {
  final VoidCallback onPressed;

  const TutorialDismissButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 56,
      right: 16,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.check, color: Colors.white),
        label: Text(
          'Mengerti',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        style: TextButton.styleFrom(
          backgroundColor: Colors.black54,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
      ),
    );
  }
}
