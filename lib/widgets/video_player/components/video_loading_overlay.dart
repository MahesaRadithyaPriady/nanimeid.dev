import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VideoLoadingOverlay extends StatelessWidget {
  final String message;
  const VideoLoadingOverlay({super.key, this.message = 'Loading video...'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Colors.pinkAccent,
            strokeWidth: 3,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
